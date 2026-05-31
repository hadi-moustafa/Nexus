import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/auth';
import { createServiceClient } from '@/lib/supabase/server';

export async function GET(req: NextRequest) {
  const user = await requireAuth(req);
  if (user instanceof NextResponse) return user;

  const { searchParams } = new URL(req.url);
  const limit = Math.min(parseInt(searchParams.get('limit') ?? '30'), 50);
  const cursor = searchParams.get('cursor');

  const supabase = createServiceClient();

  let query = supabase
    .from('notifications')
    .select('id, type, title, body, post_id, read_at, created_at')
    .eq('user_id', user.userId)
    .order('created_at', { ascending: false })
    .limit(limit + 1);

  if (cursor) {
    query = query.lt('created_at', cursor);
  }

  const { data, error } = await query;
  if (error) return NextResponse.json({ error: 'Failed to fetch notifications' }, { status: 500 });

  const hasMore = (data?.length ?? 0) > limit;
  const items = hasMore ? data!.slice(0, limit) : (data ?? []);
  const nextCursor = hasMore ? items[items.length - 1].created_at : null;
  const unreadCount = items.filter((n) => !n.read_at).length;

  return NextResponse.json({
    data: items,
    meta: { nextCursor, unreadCount },
  });
}
