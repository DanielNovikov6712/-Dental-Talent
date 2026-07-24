class ArrayInclusionValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    allowed = options[:in]
    allowed = allowed.call(record) if allowed.respond_to?(:call)

    values  = Array(value).map(&:to_s).reject(&:blank?)
    invalid = values - Array(allowed).map(&:to_s)

    return if invalid.empty?

    record.errors.add(attribute, :inclusion, value: invalid.join(", "))
  end
end
