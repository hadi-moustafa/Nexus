-- Extend the notifications.type check constraint to support account-level
-- events (subscription activated/canceled, bookmark added) in addition to
-- the existing journalist-post engagement events.
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check
  CHECK (type IN (
    'new_comment',
    'new_reaction',
    'new_post',
    'subscription_activated',
    'subscription_canceled',
    'bookmark_added'
  ));
