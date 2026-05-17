// ============================================================
// Student+ ERP — Edge Function: approve-ml-od
// Approves/rejects ML/OD and triggers recalculation
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // Verify caller is staff or admin
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (!profile || !["staff", "admin"].includes(profile.role)) {
      return new Response(JSON.stringify({ error: "Forbidden" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { ml_od_id, action } = await req.json() as { ml_od_id: string; action: "approved" | "rejected" };

    if (!ml_od_id || !["approved", "rejected"].includes(action)) {
      return new Response(JSON.stringify({ error: "ml_od_id and action (approved/rejected) required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get staff record
    const { data: staffRecord } = await supabaseAdmin
      .from("staff").select("id").eq("profile_id", user.id).single();

    // Update ML/OD status
    const { data: mlOd, error: updateErr } = await supabaseAdmin
      .from("ml_od")
      .update({
        status: action,
        approved_by: staffRecord?.id ?? null,
        approved_at: new Date().toISOString(),
      })
      .eq("id", ml_od_id)
      .select("student_id, subject_id")
      .single();

    if (updateErr || !mlOd) throw updateErr ?? new Error("ML/OD not found");

    // Trigger attendance recalculation if approved
    if (action === "approved") {
      // Get student's latest enrollment
      const { data: enrollment } = await supabaseAdmin
        .from("enrollments")
        .select("academic_year, semester_number, subject_id")
        .eq("student_id", mlOd.student_id)
        .order("enrolled_at", { ascending: false })
        .limit(1)
        .single();

      if (enrollment) {
        const subjectsToRecalc = mlOd.subject_id
          ? [mlOd.subject_id]
          : (await supabaseAdmin
              .from("enrollments")
              .select("subject_id")
              .eq("student_id", mlOd.student_id)
              .eq("academic_year", enrollment.academic_year)
            ).data?.map(e => e.subject_id) ?? [];

        for (const sid of subjectsToRecalc) {
          await supabaseAdmin.rpc("calculate_effective_attendance", {
            p_student_id:    mlOd.student_id,
            p_subject_id:    sid,
            p_academic_year: enrollment.academic_year,
            p_semester_no:   enrollment.semester_number,
          });
        }
      }
    }

    return new Response(
      JSON.stringify({ success: true, ml_od_id, action }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
