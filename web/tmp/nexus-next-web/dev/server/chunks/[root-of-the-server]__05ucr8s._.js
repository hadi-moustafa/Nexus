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
        auth: {
            persistSession: false,
            autoRefreshToken: false,
            detectSessionInUrl: false
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
"[project]/src/app/api/v1/digest/route.ts [app-route] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "GET",
    ()=>GET
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/next/server.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/supabase/server.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$auth$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/src/lib/auth.ts [app-route] (ecmascript)");
;
;
;
async function GET(request) {
    const auth = await (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$auth$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["requireAuth"])(request);
    if (auth instanceof __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"]) return auth;
    try {
        // Use service client throughout — no cookie lock contention
        const supabase = (0, __TURBOPACK__imported__module__$5b$project$5d2f$src$2f$lib$2f$supabase$2f$server$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["createServiceClient"])();
        // Verify premium subscription
        const { data: sub } = await supabase.from("subscriptions").select("status").eq("user_id", auth.userId).single();
        const isPremium = sub?.status === "active" || sub?.status === "trialing";
        if (!isPremium) {
            return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
                error: {
                    code: "FORBIDDEN",
                    message: "Premium subscription required"
                }
            }, {
                status: 403
            });
        }
        // Get user's preferred language for cohort selection
        const { data: prefs } = await supabase.from("user_preferences").select("preferred_language").eq("user_id", auth.userId).single();
        const language = prefs?.preferred_language ?? "en";
        const today = new Date().toISOString().slice(0, 10);
        // Try user's language cohort first, then fall back to "en"
        const { data: digest } = await supabase.from("digests").select("id, cohort_key, digest_date, introduction, stories, article_count, generated_at").eq("digest_date", today).in("cohort_key", [
            language,
            "en"
        ]).order("cohort_key", {
            ascending: false
        }).limit(1).single();
        if (digest) {
            return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
                data: digest
            });
        }
        // No digest yet — generate on demand
        // Try last 24h first, fall back to last 7 days, then just the most recent articles
        const lang = language === "ar" || language === "fr" ? language : "en";
        async function fetchArticles(since, language) {
            return (await supabase.from("articles").select("id, title, description, url, category, language").gte("published_at", since).eq("language", language).order("published_at", {
                ascending: false
            }).limit(10)).data ?? [];
        }
        const since24h = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
        const since7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
        let effectiveArticles = await fetchArticles(since24h, lang);
        // Widen to 7 days if sparse
        if (effectiveArticles.length < 3) {
            effectiveArticles = await fetchArticles(since7d, lang);
        }
        // Fall back to English if still sparse
        if (effectiveArticles.length < 3 && lang !== "en") {
            effectiveArticles = await fetchArticles(since24h, "en");
            if (effectiveArticles.length < 3) {
                effectiveArticles = await fetchArticles(since7d, "en");
            }
        }
        // Last resort: newest 10 articles regardless of language or date
        if (effectiveArticles.length === 0) {
            effectiveArticles = (await supabase.from("articles").select("id, title, description, url, category, language").order("published_at", {
                ascending: false
            }).limit(10)).data ?? [];
        }
        if (!effectiveArticles || effectiveArticles.length === 0) {
            return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
                error: {
                    code: "NOT_FOUND",
                    message: "No articles available to generate a digest"
                }
            }, {
                status: 404
            });
        }
        let generatedDigest;
        if (process.env.GEMINI_API_KEY) {
            // Full AI generation
            const { generateDigest } = await __turbopack_context__.A("[project]/src/lib/gemini.ts [app-route] (ecmascript, async loader)");
            generatedDigest = await generateDigest(effectiveArticles.map((a)=>({
                    id: a.id,
                    title: a.title,
                    description: a.description,
                    url: a.url,
                    category: a.category ?? "general"
                })), lang);
        } else {
            // Plain fallback — no AI
            generatedDigest = {
                introduction: `Here are today's top ${effectiveArticles.length} stories from around the world.`,
                stories: effectiveArticles.map((a)=>({
                        title: a.title,
                        summary: a.description ?? "No summary available.",
                        category: a.category ?? "general",
                        url: a.url,
                        articleId: a.id
                    }))
            };
        }
        // Persist so subsequent requests are fast
        // Upsert handles race conditions (two users hitting digest at the same time)
        const { data: inserted } = await supabase.from("digests").upsert({
            cohort_key: lang,
            digest_date: today,
            introduction: generatedDigest.introduction,
            stories: generatedDigest.stories,
            article_count: generatedDigest.stories.length
        }, {
            onConflict: "cohort_key,digest_date"
        }).select("id, cohort_key, digest_date, introduction, stories, article_count, generated_at").single();
        return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
            data: inserted ?? {
                ...generatedDigest,
                digest_date: today,
                cohort_key: lang,
                article_count: generatedDigest.stories.length,
                generated_at: new Date().toISOString()
            }
        });
    } catch (err) {
        console.error("[GET /api/v1/digest]", err);
        return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
            error: {
                code: "INTERNAL_ERROR",
                message: "Failed to fetch digest"
            }
        }, {
            status: 500
        });
    }
}
}),
];

//# sourceMappingURL=%5Broot-of-the-server%5D__05ucr8s._.js.map