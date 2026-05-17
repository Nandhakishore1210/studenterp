// ============================================================
// Student+ ERP — Edge Function: calculate-attendance
// Triggered via HTTP POST or directly from DB trigger proxy
// Recalculates attendance_effective for a student/subject
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CalcRequest {
  student_id?: string;     // single student
  subject_id?: string;     // single subject
  academic_year: string;
  semester_number: number;
  recalculate_all?: boolean; // recalculate all students for a subject assignment
  subject_assignment_id?: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const body: CalcRequest = await req.json();
    const { student_id, subject_id, academic_year, semester_number, recalculate_all, subject_assignment_id } = body;

    if (!academic_year || !semester_number) {
      return new Response(
        JSON.stringify({ error: "academic_year and semester_number are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const results: { student_id: string; subject_id: string; success: boolean }[] = [];

    if (recalculate_all && subject_assignment_id) {
      // Recalculate for all students enrolled in this subject assignment
      const { data: enrollments, error: enrErr } = await supabase
        .from("enrollments")
        .select("student_id, subject_id")
        .eq("subject_assignment_id", subject_assignment_id)
        .eq("academic_year", academic_year)
        .eq("semester_number", semester_number);

      if (enrErr) throw enrErr;

      for (const enr of enrollments ?? []) {
        const { error } = await supabase.rpc("calculate_effective_attendance", {
          p_student_id:    enr.student_id,
          p_subject_id:    enr.subject_id,
          p_academic_year: academic_year,
          p_semester_no:   semester_number,
        });
        results.push({ student_id: enr.student_id, subject_id: enr.subject_id, success: !error });
      }
    } else if (student_id && subject_id) {
      // Single student/subject
      const { error } = await supabase.rpc("calculate_effective_attendance", {
        p_student_id:    student_id,
        p_subject_id:    subject_id,
        p_academic_year: academic_year,
        p_semester_no:   semester_number,
      });
      results.push({ student_id, subject_id, success: !error });
    } else if (student_id) {
      // All subjects for a student
      const { data: enrollments, error: enrErr } = await supabase
        .from("enrollments")
        .select("subject_id")
        .eq("student_id", student_id)
        .eq("academic_year", academic_year)
        .eq("semester_number", semester_number);

      if (enrErr) throw enrErr;

      for (const enr of enrollments ?? []) {
        const { error } = await supabase.rpc("calculate_effective_attendance", {
          p_student_id:    student_id,
          p_subject_id:    enr.subject_id,
          p_academic_year: academic_year,
          p_semester_no:   semester_number,
        });
        results.push({ student_id, subject_id: enr.subject_id, success: !error });
      }
    } else {
      return new Response(
        JSON.stringify({ error: "Provide student_id, subject_id, or set recalculate_all with subject_assignment_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const failCount = results.filter(r => !r.success).length;
    return new Response(
      JSON.stringify({ success: true, calculated: results.length, failed: failCount, results }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
