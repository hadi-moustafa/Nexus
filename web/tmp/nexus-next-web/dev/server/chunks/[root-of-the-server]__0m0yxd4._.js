module.exports = [
"[externals]/next/dist/compiled/next-server/app-route-turbo.runtime.dev.js [external] (next/dist/compiled/next-server/app-route-turbo.runtime.dev.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/compiled/next-server/app-route-turbo.runtime.dev.js", () => require("next/dist/compiled/next-server/app-route-turbo.runtime.dev.js"));

module.exports = mod;
}),
"[externals]/next/dist/compiled/@opentelemetry/api [external] (next/dist/compiled/@opentelemetry/api, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/compiled/@opentelemetry/api", () => require("next/dist/compiled/@opentelemetry/api"));

module.exports = mod;
}),
"[externals]/next/dist/compiled/next-server/app-page-turbo.runtime.dev.js [external] (next/dist/compiled/next-server/app-page-turbo.runtime.dev.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/compiled/next-server/app-page-turbo.runtime.dev.js", () => require("next/dist/compiled/next-server/app-page-turbo.runtime.dev.js"));

module.exports = mod;
}),
"[externals]/next/dist/server/app-render/work-unit-async-storage.external.js [external] (next/dist/server/app-render/work-unit-async-storage.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/server/app-render/work-unit-async-storage.external.js", () => require("next/dist/server/app-render/work-unit-async-storage.external.js"));

module.exports = mod;
}),
"[externals]/next/dist/server/app-render/work-async-storage.external.js [external] (next/dist/server/app-render/work-async-storage.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/server/app-render/work-async-storage.external.js", () => require("next/dist/server/app-render/work-async-storage.external.js"));

module.exports = mod;
}),
"[externals]/next/dist/shared/lib/no-fallback-error.external.js [external] (next/dist/shared/lib/no-fallback-error.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/shared/lib/no-fallback-error.external.js", () => require("next/dist/shared/lib/no-fallback-error.external.js"));

module.exports = mod;
}),
"[externals]/next/dist/server/app-render/after-task-async-storage.external.js [external] (next/dist/server/app-render/after-task-async-storage.external.js, cjs)", ((__turbopack_context__, module, exports) => {

const mod = __turbopack_context__.x("next/dist/server/app-render/after-task-async-storage.external.js", () => require("next/dist/server/app-render/after-task-async-storage.external.js"));

module.exports = mod;
}),
"[project]/src/lib/supabase/server.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "createClient",
    ()=>createClient,
    "createPublicClient",
    ()=>createPublicClient,
    "createServiceClient",
    ()=>createServiceClient
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f40$supabase$2f$ssr$2f$dist$2f$module$2f$index$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__$3c$locals$3e$__ = __turbopack_context__.i("[project]/node_modules/@supabase/ssr/dist/module/index.js [app-route] (ecmascript) <locals>");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f40$supabase$2f$ssr$2f$dist$2f$module$2f$createServerClient$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/@supabase/ssr/dist/module/createServerClient.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f40$supabase$2f$supabase$2d$js$2f$dist$2f$index$2e$mjs__$5b$app$2d$route$5d$__$28$ecmascript$29$__$3c$locals$3e$__ = __turbopack_context__.i("[project]/node_modules/@supabase/supabase-js/dist/index.mjs [app-route] (ecmascript) <locals>");
;
;
const supabaseUrl = ("TURBOPACK compile-time value", "https://gfbcwqeocdrzbyaenlnh.supabase.co");
const supabaseKey = ("TURBOPACK compile-time value", "sb_publishable_-m1X2AYSipLmAQ5OYafaDA_ruIVwSR6");
const createClient = (cookieStore)=>{
    return (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f40$supabase$2f$ssr$2f$dist$2f$module$2f$createServerClient$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["createServerClient"])(supabaseUrl, supabaseKey, {
        cookies: {
            getAll () {
                return cookieStore.getAll();
            },
            setAll (cookiesToSet) {
                try {
                    cookiesToSet.forEach(({ name, value, options })=>cookieStore.set(name, value, options));
                } catch  {
                // Called from a Server Component — safe to ignore.
                }
            }
        }
    });
};
const createPublicClient = ()=>(0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f40$supabase$2f$supabase$2d$js$2f$dist$2f$index$2e$mjs__$5b$app$2d$route$5d$__$28$ecmascript$29$__$3c$locals$3e$__["createClient"])(supabaseUrl, supabaseKey, {
        global: {
            fetch: (url, options)=>{
                const controller = new AbortController();
                const timer = setTimeout(()=>controller.abort(), 15000);
                return fetch(url, {
                    ...options,
                    signal: controller.signal
                }).finally(()=>clearTimeout(timer));
            }
        }
    });
const createServiceClient = ()=>(0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f40$supabase$2f$supabase$2d$js$2f$dist$2f$index$2e$mjs__$5b$app$2d$route$5d$__$28$ecmascript$29$__$3c$locals$3e$__["createClient"])(supabaseUrl, process.env.SUPABASE_SERVICE_ROLE_KEY);
}),
"[project]/src/lib/auth.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "requireAuth",
    ()=>requireAuth
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f40$supabase$2f$ssr$2f$dist$2f$module$2f$index$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__$3c$locals$3e$__ = __turbopack_context__.i("[project]/node_modules/@supabase/ssr/dist/module/index.js [app-route] (ecmascript) <locals>");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f40$supabase$2f$ssr$2f$dist$2f$module$2f$createServerClient$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/@supabase/ssr/dist/module/createServerClient.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$headers$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/headers.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/server.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/supabase/server.ts [app-route] (ecmascript)");
;
;
;
;
async function requireAuth(request) {
    const unauthorized = (msg = "Not authenticated")=>__TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
            error: {
                code: "UNAUTHORIZED",
                message: msg
            }
        }, {
            status: 401
        });
    // ── Mobile: Authorization header ─────────────────────────────────────────
    const authHeader = request.headers.get("authorization");
    if (authHeader?.startsWith("Bearer ")) {
        const token = authHeader.slice(7);
        const supabase = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["createServiceClient"])();
        const { data, error } = await supabase.auth.getUser(token);
        if (error || !data.user) return unauthorized("Invalid or expired token");
        return {
            userId: data.user.id,
            email: data.user.email
        };
    }
    // ── Web: cookie-based session via @supabase/ssr ───────────────────────────
    // Use createServerClient instead of hand-rolling cookie parsing so that
    // the correct cookie name, chunking, and encoding are handled automatically.
    try {
        const cookieStore = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$headers$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["cookies"])();
        const supabase = (0, __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f40$supabase$2f$ssr$2f$dist$2f$module$2f$createServerClient$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["createServerClient"])(("TURBOPACK compile-time value", "https://gfbcwqeocdrzbyaenlnh.supabase.co"), ("TURBOPACK compile-time value", "sb_publishable_-m1X2AYSipLmAQ5OYafaDA_ruIVwSR6"), {
            cookies: {
                getAll: ()=>cookieStore.getAll(),
                setAll: (cookiesToSet)=>{
                    try {
                        cookiesToSet.forEach(({ name, value, options })=>cookieStore.set(name, value, options));
                    } catch  {
                    // Called from a Route Handler — safe to ignore set errors.
                    }
                }
            }
        });
        const { data: { user }, error } = await supabase.auth.getUser();
        if (error || !user) return unauthorized();
        return {
            userId: user.id,
            email: user.email
        };
    } catch  {
        return unauthorized();
    }
}
}),
"[project]/src/lib/db/users.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "getUserPreferences",
    ()=>getUserPreferences,
    "getUserProfile",
    ()=>getUserProfile,
    "getUserStats",
    ()=>getUserStats,
    "updateUserPreferences",
    ()=>updateUserPreferences
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/supabase/server.ts [app-route] (ecmascript)");
;
// ---------------------------------------------------------------------------
// Row mapping — snake_case DB columns → camelCase API types
// ---------------------------------------------------------------------------
function rowToUserProfile(row) {
    return {
        id: row.id,
        email: row.email,
        displayName: row.display_name ?? null,
        avatarUrl: row.avatar_url ?? null,
        createdAt: row.created_at
    };
}
function rowToPreferences(row) {
    return {
        topics: row.topics ?? [],
        preferredLanguage: row.preferred_language ?? "en",
        onboardingComplete: row.onboarding_complete ?? false
    };
}
function rowToStats(row) {
    return {
        totalXp: row.total_xp ?? 0,
        currentStreak: row.current_streak ?? 0,
        longestStreak: row.longest_streak ?? 0,
        quizzesCompleted: row.quizzes_completed ?? 0,
        perfectScores: row.perfect_scores ?? 0,
        articlesRead: row.articles_read ?? 0
    };
}
async function getUserProfile(userId) {
    const supabase = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["createServiceClient"])();
    const { data, error } = await supabase.from("users").select("id, email, display_name, avatar_url, created_at").eq("id", userId).single();
    if (error) {
        if (error.code === "PGRST116") return null; // not found
        throw error;
    }
    return data ? rowToUserProfile(data) : null;
}
async function getUserPreferences(userId) {
    const supabase = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["createServiceClient"])();
    const { data, error } = await supabase.from("user_preferences").select("topics, preferred_language, onboarding_complete").eq("user_id", userId).single();
    if (error) {
        if (error.code === "PGRST116") return null;
        throw error;
    }
    return data ? rowToPreferences(data) : null;
}
async function updateUserPreferences(userId, patch) {
    const supabase = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["createServiceClient"])();
    const dbPatch = {};
    if (patch.topics !== undefined) dbPatch.topics = patch.topics;
    if (patch.preferredLanguage !== undefined) dbPatch.preferred_language = patch.preferredLanguage;
    if (patch.onboardingComplete !== undefined) dbPatch.onboarding_complete = patch.onboardingComplete;
    dbPatch.updated_at = new Date().toISOString();
    const { data, error } = await supabase.from("user_preferences").update(dbPatch).eq("user_id", userId).select("topics, preferred_language, onboarding_complete").single();
    if (error) throw error;
    return rowToPreferences(data);
}
async function getUserStats(userId) {
    const supabase = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["createServiceClient"])();
    const { data, error } = await supabase.from("user_stats").select("total_xp, current_streak, longest_streak, quizzes_completed, perfect_scores, articles_read").eq("user_id", userId).single();
    if (error) {
        if (error.code === "PGRST116") return null;
        throw error;
    }
    return data ? rowToStats(data) : null;
}
}),
"[project]/src/app/api/v1/auth/session/route.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "GET",
    ()=>GET
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$auth$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/auth.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/supabase/server.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$db$2f$users$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/db/users.ts [app-route] (ecmascript)");
;
;
;
async function GET(request) {
    const auth = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$auth$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["requireAuth"])(request);
    if (auth instanceof Response) return auth; // 401
    try {
        const supabase = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["createServiceClient"])();
        // Get auth metadata (provider) — requires service-role admin API so it
        // works for both cookie-based web sessions and Bearer-token mobile calls.
        const { data: { user: authUser } } = await supabase.auth.admin.getUserById(auth.userId);
        const provider = authUser?.app_metadata?.provider ?? "email";
        let profile = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$db$2f$users$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["getUserProfile"])(auth.userId);
        if (!profile) {
            // No DB row yet — create all three rows now (idempotent upserts).
            // This covers mobile users where auth/callback is never called.
            await Promise.all([
                supabase.from("users").upsert({
                    id: auth.userId,
                    email: auth.email,
                    display_name: authUser?.user_metadata?.full_name ?? authUser?.user_metadata?.name ?? null,
                    avatar_url: authUser?.user_metadata?.avatar_url ?? authUser?.user_metadata?.picture ?? null,
                    updated_at: new Date().toISOString()
                }, {
                    onConflict: "id"
                }),
                supabase.from("user_preferences").upsert({
                    user_id: auth.userId,
                    topics: [],
                    preferred_language: "en",
                    onboarding_complete: false
                }, {
                    onConflict: "user_id",
                    ignoreDuplicates: true
                }),
                supabase.from("user_stats").upsert({
                    user_id: auth.userId,
                    total_xp: 0,
                    current_streak: 0,
                    longest_streak: 0,
                    quizzes_completed: 0,
                    perfect_scores: 0,
                    articles_read: 0
                }, {
                    onConflict: "user_id",
                    ignoreDuplicates: true
                })
            ]);
            // Re-fetch so we return the freshly-created row
            profile = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$db$2f$users$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["getUserProfile"])(auth.userId);
        }
        if (!profile) {
            // Extremely unlikely — upsert succeeded but read returned nothing.
            // Return a synthetic profile so the client can proceed.
            return Response.json({
                data: {
                    id: auth.userId,
                    email: auth.email ?? null,
                    displayName: null,
                    avatarUrl: null,
                    createdAt: new Date().toISOString(),
                    provider,
                    isAdmin: false
                }
            });
        }
        const { data: roleRow } = await supabase.from("users").select("role").eq("id", auth.userId).single();
        const isAdmin = roleRow?.role === "admin";
        return Response.json({
            data: {
                ...profile,
                provider,
                isAdmin
            }
        });
    } catch (err) {
        console.error("[GET /api/v1/auth/session]", err);
        return Response.json({
            error: {
                code: "INTERNAL_ERROR",
                message: "Failed to fetch session"
            }
        }, {
            status: 500
        });
    }
}
}),
];

//# sourceMappingURL=%5Broot-of-the-server%5D__0m0yxd4._.js.map