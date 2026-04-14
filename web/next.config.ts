import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  reactCompiler: true,
  // Move the Turbopack dev cache to /tmp (tmpfs / RAM) to avoid the
  // "Slow filesystem detected" warning on LUKS-encrypted or network drives.
  distDir: process.env.NODE_ENV === "development"
    ? `/tmp/nexus-next-${path.basename(process.cwd())}`
    : ".next",
};

export default nextConfig;
