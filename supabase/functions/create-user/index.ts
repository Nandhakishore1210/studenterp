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
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Verify caller is admin
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabaseUser.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: callerProfile } = await supabaseAdmin
      .from("profiles").select("role").eq("id", user.id).single();

    if (callerProfile?.role !== "admin") {
      return new Response(JSON.stringify({ error: "Only admins can create accounts" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const {
      email, password, full_name, role, university_id,
      // staff fields
      employee_id, department_id, designation, roles,
      // student fields
      register_no, course_id, current_semester, batch, section,
    } = body;

    if (!email || !password || !full_name || !role) {
      return new Response(JSON.stringify({ error: "email, password, full_name, role are required" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create auth user
    const { data: { user: newUser }, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name, role, university_id },
    });

    if (createError || !newUser) {
      return new Response(JSON.stringify({ error: createError?.message ?? "Failed to create user" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Wait briefly for trigger to create profile
    await new Promise(resolve => setTimeout(resolve, 800));

    // Update profile university_id
    if (university_id) {
      await supabaseAdmin.from("profiles")
        .update({ university_id })
        .eq("id", newUser.id);
    }

    if (role === "staff") {
      const empId = employee_id || `EMP-${Date.now()}`;
      const { data: staffRecord, error: staffErr } = await supabaseAdmin
        .from("staff")
        .insert({ profile_id: newUser.id, employee_id: empId, department_id, designation: designation || "Faculty" })
        .select("id").single();

      if (staffErr) {
        return new Response(JSON.stringify({ error: `Profile created but staff insert failed: ${staffErr.message}` }), {
          status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const staffRoles: string[] = roles?.length ? roles : ["subject_faculty"];
      for (const r of staffRoles) {
        await supabaseAdmin.from("staff_roles")
          .insert({ staff_id: staffRecord.id, role: r })
          .select();
      }
    } else if (role === "student") {
      const { error: stuErr } = await supabaseAdmin.from("students").insert({
        profile_id: newUser.id,
        register_no: register_no || `REG${Date.now()}`,
        department_id,
        course_id,
        current_semester: current_semester || 1,
        batch: batch || "2025",
        section: section || "A",
      });

      if (stuErr) {
        return new Response(JSON.stringify({ error: `Profile created but student insert failed: ${stuErr.message}` }), {
          status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    return new Response(
      JSON.stringify({ success: true, user_id: newUser.id, email: newUser.email }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
