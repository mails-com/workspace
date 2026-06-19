# Email Verification Results

`POST /v1/validate` returns a JSON object for every email address checked. The two most important fields are `status` and `reason`. Everything else provides additional signal you can use to filter or score your list.

---

## All states and reasons at a glance

| `status` | `reason` | What it means |
|---|---|---|
| `deliverable` | `accepted_email` | Mail server confirmed the mailbox exists and can receive mail |
| `risky` | `accept_all` | Domain accepts every address — individual mailbox existence unconfirmed |
| `risky` | `mailbox_full` | Mailbox exists but is over quota (SMTP 452) |
| `risky` | `low_quality` | Address is from a disposable / temporary email provider |
| `risky` | `low_deliverability` | MX records exist but delivery confidence is low |
| `undeliverable` | `invalid_email` | Address fails format validation |
| `undeliverable` | `invalid_domain` | Domain does not exist or has no valid DNS records |
| `undeliverable` | `rejected_email` | Mail server rejected the mailbox — it does not exist (SMTP 550) |
| `undeliverable` | `invalid_smtp` | Mail server returned an unexpected or invalid SMTP response |
| `undeliverable` | `low_deliverability` | Domain has no MX records — cannot receive mail |
| `unknown` | *(omitted)* | MX records found but SMTP check was inconclusive — not necessarily invalid |
| `unknown` | `no_connect` | Could not establish a connection to the mail server |
| `unknown` | `timeout` | DNS lookup or SMTP session timed out before completing |
| `unknown` | `unavailable_smtp` | Mail server was temporarily unavailable |
| `unknown` | `unexpected_error` | An unexpected error occurred during verification |

---

## Status explanations

### deliverable

The mail server actively confirmed that the mailbox exists and can receive mail. This is the strongest positive result — safe to send to.

**Reason:** `accepted_email`

### risky

The address may exist, but one or more signals reduce confidence. Risky addresses are not automatically invalid — decide based on your tolerance for bounces or engagement risk.

| Reason | When it occurs |
|---|---|
| `accepted_email` → `accept_all` | The domain accepts any RCPT TO command, so individual mailbox existence cannot be confirmed |
| `mailbox_full` | The mail server returned SMTP 452, meaning the mailbox is over quota |
| `low_quality` | The domain belongs to a known disposable or temporary email provider |
| `low_deliverability` | MX records are present but the mail server did not provide a clear accept or reject |

### undeliverable

The address cannot receive mail. Score is always `0`. Remove these from your active lists.

| Reason | When it occurs |
|---|---|
| `invalid_email` | The address fails format parsing (missing `@`, invalid characters, etc.) |
| `invalid_domain` | The domain does not exist or has no resolvable DNS records |
| `rejected_email` | The SMTP server explicitly rejected the mailbox with a 5xx permanent failure |
| `invalid_smtp` | The server responded with an unexpected SMTP code that could not be interpreted |
| `low_deliverability` | No MX records were found for the domain — no mail server to deliver to |

### unknown

The verification could not reach a confident conclusion. This is not the same as undeliverable — the address may still be valid. Unknown results are often caused by temporary server conditions.

When `status` is `unknown` and the address is not disposable, the `reason` field is **omitted** from the response. Otherwise one of the following reasons is returned:

| Reason | When it occurs |
|---|---|
| `no_connect` | TCP connection to the mail server was refused or unreachable |
| `timeout` | The DNS query or SMTP session exceeded the time limit |
| `unavailable_smtp` | The server greylisted the request or returned a temporary 4xx error |
| `unexpected_error` | An internal error occurred that prevented the check from completing |

Unknown emails caused by `timeout` or `unavailable_smtp` are often worth retrying — the underlying mailbox may be perfectly valid.

---

## Score

Every result includes a `score` from `0` to `100` indicating overall deliverability confidence. It is calculated from the signals below:

| Signal | Points |
|---|---|
| MX records found | +30 |
| SMTP confirmed deliverable | +40 |
| Not a disposable address | +15 |
| Not an accept-all domain | +10 |
| Not a role address | +5 |

**Special rules:**
- `status: undeliverable` → score is always **0**, regardless of other signals
- `status: unknown` → score is **capped at 45**, regardless of other signals

A score of **100** is only achievable for a fully deliverable, non-disposable, non-role, non-accept-all address.

---

## Response fields

### Core

| Field | Type | Description |
|---|---|---|
| `email` | string | The normalized email address that was verified |
| `status` | string | One of `deliverable`, `risky`, `undeliverable`, `unknown` |
| `reason` | string | Sub-reason for the status (omitted for clean `unknown` results) |
| `score` | integer | Deliverability confidence score, 0–100 |

### Domain

| Field | Type | Description |
|---|---|---|
| `domain` | string | The domain portion of the email address |
| `free` | boolean | `true` if the domain is a known free email provider (Gmail, Yahoo, etc.) |
| `disposable` | boolean | `true` if the domain is a known disposable / temporary email provider |
| `role` | boolean | `true` if the local part is a role address (info@, support@, admin@, etc.) |
| `no_reply` | boolean | `true` if the address is a no-reply address |
| `mx` | array | List of MX records for the domain, ordered by priority |
| `mx_record` | string | Hostname of the highest-priority MX record (empty if none found) |
| `smtp_provider` | string | Detected mail provider (e.g. `Google`, `Microsoft`), when identifiable |

### Mailbox signals

| Field | Type | Description |
|---|---|---|
| `accept_all` | boolean | `true` if the domain accepts any RCPT TO — individual mailbox existence unconfirmed |
| `mailbox_full` | boolean | `true` if the mail server indicated the mailbox is over quota (SMTP 452) |

### Address parts

| Field | Type | Description |
|---|---|---|
| `user` | string | The local part of the address (before `@`) |
| `tag` | string\|null | The sub-address tag if present (e.g. `+tag` in `user+tag@domain.com`) |
| `did_you_mean` | string\|null | A suggested correction for common domain typos (e.g. `user@gmail.com` if `gmial.com` was submitted) |

---

## Example responses

### Deliverable

```json
{
  "email": "jane@acme.com",
  "status": "deliverable",
  "reason": "accepted_email",
  "score": 100,
  "domain": "acme.com",
  "free": false,
  "disposable": false,
  "role": false,
  "no_reply": false,
  "accept_all": false,
  "mailbox_full": false,
  "user": "jane",
  "tag": null,
  "did_you_mean": null,
  "mx": [{ "host": "mail.acme.com", "preference": 10 }],
  "mx_record": "mail.acme.com",
  "smtp_provider": ""
}
```

### Risky — accept-all domain

```json
{
  "email": "john@company.com",
  "status": "risky",
  "reason": "accept_all",
  "score": 35,
  "accept_all": true,
  "mailbox_full": false,
  "disposable": false,
  ...
}
```

### Undeliverable — rejected mailbox

```json
{
  "email": "nobody@gmail.com",
  "status": "undeliverable",
  "reason": "rejected_email",
  "score": 0,
  "mx_record": "aspmx.l.google.com",
  "smtp_provider": "Google",
  ...
}
```

### Unknown — inconclusive SMTP

```json
{
  "email": "user@example.com",
  "status": "unknown",
  "score": 30,
  "mx_record": "mail.example.com",
  ...
}
```

Note: `reason` is absent in this response — the domain has MX records but SMTP gave no conclusive answer.
