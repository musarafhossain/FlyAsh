import type { BaseModel } from '@adonisjs/lucid/orm'
import type { NormalizeConstructor } from '@adonisjs/core/types/helpers'
import { v7 as uuidv7 } from 'uuid'

/**
 * Primary key is a UUID v7 (time ordered, so ORDER BY id is still
 * "oldest first"), assigned by the app before the row is inserted.
 */
export function withUuid<T extends NormalizeConstructor<typeof BaseModel>>(superclass: T) {
  class WithUuid extends superclass {
    static selfAssignPrimaryKey = true

    static boot() {
      // Own property only: the generated schema parent is already booted.
      if (Object.hasOwn(this, 'booted') && this.booted) return
      super.boot()
      this.before('create', (model: any) => {
        if (!model.id) model.id = uuidv7()
      })
    }
  }
  return WithUuid
}

export const newId = () => uuidv7()
