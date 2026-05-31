import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/auth';
import { createServiceClient } from '@/lib/supabase/server';

export async function POST(req: NextRequest) {
  const user = await requireAuth(req);
  if (user instanceof NextResponse) return user;

  const supabase = createServiceClient();

  const { error } = await supabase
    .from('notifications')
    .update({ read_at: new Date().toISOString() })
    .eq('user_id', user.userId)
    .is('read_at', null);

  if (error) return NextResponse.json({ error: 'Failed to mark read' }, { status: 500 });

  return NextResponse.json({ data: { ok: true } });
}
