/**
 * Money helpers.
 *
 * All calculations are done in integer paise (1 ₹ = 100 paise), so there are
 * no floating point errors. Values come from the DB / API as strings with
 * 2 decimals ("1500.00") and go back the same way.
 */

/** "1500.50" | 1500.5 → 150050 */
export function toPaise(value: string | number | null | undefined): number {
  if (value === null || value === undefined || value === '') return 0
  const text = typeof value === 'number' ? value.toFixed(2) : String(value).trim()
  const negative = text.startsWith('-')
  const [whole, fraction = ''] = text.replace('-', '').split('.')
  const paise = Number(whole || '0') * 100 + Number((fraction + '00').slice(0, 2))
  return negative ? -paise : paise
}

/** 150050 → "1500.50" */
export function fromPaise(paise: number): string {
  const sign = paise < 0 ? '-' : ''
  const abs = Math.abs(Math.round(paise))
  return `${sign}${Math.floor(abs / 100)}.${String(abs % 100).padStart(2, '0')}`
}

/** quantity × unit amount, rounded to the nearest paisa. */
export function multiply(quantity: string | number, unitAmount: string | number): number {
  // quantity in hundredths × amount in paise → result in hundredths of paise
  return Math.round((toPaise(quantity) * toPaise(unitAmount)) / 100)
}

/** Normalise any money input to a 2-decimal string. */
export function money(value: string | number | null | undefined): string {
  return fromPaise(toPaise(value))
}
