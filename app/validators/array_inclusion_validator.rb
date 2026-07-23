# Validates that every element of an array attribute is one of the allowed
# values. Used for the multi-select JSON columns on CandidateProfile.
#
#   validates :transport_types, array_inclusion: { in: %w[bike car] }
#
# Blank elements are ignored (they are stripped before validation); requiring
# "at least one" is left to a separate presence validation.
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
