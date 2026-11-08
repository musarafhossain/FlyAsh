import env from '#start/env'
import app from '@adonisjs/core/services/app'

/** Absolute folder where uploaded files are stored. */
export function uploadsPath(...paths: string[]) {
  return app.makePath('storage/uploads', ...paths)
}

/** Public URL of an uploaded file ("2026/11/abc.jpg" → "http://.../uploads/2026/11/abc.jpg"). */
export function uploadUrl(path: string | null | undefined): string | null {
  if (!path) return null
  return `${env.get('APP_URL').replace(/\/$/, '')}/uploads/${path}`
}
