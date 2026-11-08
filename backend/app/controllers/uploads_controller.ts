import type { HttpContext } from '@adonisjs/core/http'
import { randomUUID } from 'node:crypto'
import { existsSync } from 'node:fs'
import { normalize } from 'node:path'
import AppError from '#exceptions/app_error'
import { created } from '#helpers/api_response'
import { now } from '#helpers/dates'
import { uploadUrl, uploadsPath } from '#helpers/uploads'
import { uploadValidator } from '#validators/expense'

export default class UploadsController {
  /**
   * POST /uploads (multipart: file, folder=expenses|logo) → { path, url }
   * Images only (jpg, jpeg, png, webp), max 5 MB.
   */
  async store({ request, response }: HttpContext) {
    const { folder } = await request.validateUsing(uploadValidator)
    const file = request.file('file', { size: '5mb', extnames: ['jpg', 'jpeg', 'png', 'webp'] })

    if (!file) {
      throw new AppError('Validation failed', 422, {
        errors: [{ field: 'file', message: 'Please choose an image' }],
      })
    }
    if (!file.isValid) {
      throw new AppError('Validation failed', 422, {
        errors: file.errors.map((error) => ({ field: 'file', message: error.message })),
      })
    }

    const dir = `${folder}/${now().toFormat('yyyy/MM')}`
    const name = `${randomUUID()}.${file.extname!.toLowerCase()}`
    await file.move(uploadsPath(dir), { name })

    const path = `${dir}/${name}`
    return created(response, { path, url: uploadUrl(path) }, 'File uploaded')
  }

  /**
   * GET /uploads/* : serves uploaded files in development
   * (Nginx serves this folder directly in production).
   */
  async show({ params, response }: HttpContext) {
    const relative = normalize((params['*'] as string[]).join('/'))
    if (relative.startsWith('..') || relative.includes(`..`)) {
      throw new AppError('File not found', 404)
    }
    const absolute = uploadsPath(relative)
    if (!existsSync(absolute)) {
      throw new AppError('File not found', 404)
    }
    return response.download(absolute)
  }
}
