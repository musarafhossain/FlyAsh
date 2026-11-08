/**
 * A business-rule error with a message that is safe to show to the user.
 * The exception handler turns it into the standard error envelope.
 *
 *   throw new AppError('Cannot cancel a booking that has payments')
 *   throw new AppError('Product is used in sales', 409)
 */
export default class AppError extends Error {
  constructor(
    message: string,
    public status = 400,
    public data: unknown = null
  ) {
    super(message)
    this.name = 'AppError'
  }
}
