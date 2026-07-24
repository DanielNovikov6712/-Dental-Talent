module DateRangeValidatable
  extend ActiveSupport::Concern

  included do
    validate :end_not_before_start
  end

  private

  def end_not_before_start
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, :before_start)
  end
end
