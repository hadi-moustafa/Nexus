"use client";

import { useEffect, useRef } from "react";

interface Props {
  articleId: string;
}

export function ArticleViewTracker({ articleId }: Props) {
  const fired = useRef(false);

  useEffect(() => {
    if (fired.current) return;
    fired.current = true;
    fetch(`/api/v1/articles/${articleId}/view`, { method: "POST" }).catch(() => null);
  }, [articleId]);

  return null;
}
