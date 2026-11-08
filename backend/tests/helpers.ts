import User from '#models/user'

let counter = 0

/** Creates an active user with a unique phone. Password: "secret123". */
export async function createUser(
  overrides: Partial<{ name: string; phone: string; email: string | null; isActive: boolean }> = {}
) {
  counter += 1
  return User.create({
    name: overrides.name ?? `User ${counter}`,
    phone: overrides.phone ?? `9${String(Date.now()).slice(-6)}${String(counter).padStart(3, '0')}`,
    email: overrides.email ?? null,
    password: 'secret123',
    isActive: overrides.isActive ?? true,
  })
}

export const API = '/api/v1'
