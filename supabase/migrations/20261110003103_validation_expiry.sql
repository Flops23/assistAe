-- CHECK aceita NULL: resultados admitidos precisam de validade explicitamente não nula.
alter table private.media_validations add constraint media_validations_admitted_expiry
 check(status not in ('valid','inconclusive') or (expires_at is not null and assessed_at is not null and expires_at>assessed_at));
