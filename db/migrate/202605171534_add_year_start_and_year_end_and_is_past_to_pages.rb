class AddYearStartAndYearEndAndIsPastToPages < ActiveRecord::Migration[8.0]
  def change
    ActiveRecord::Migration.add_column(:pages, :period_start, :string) unless column_exists?(:pages, :period_start)
    ActiveRecord::Migration.add_column(:pages, :date_start_int, :integer) unless column_exists?(:pages, :date_start_int)
    ActiveRecord::Migration.add_column(:pages, :period_end, :string) unless column_exists?(:pages, :period_end)
    ActiveRecord::Migration.add_column(:pages, :date_end_int, :integer) unless column_exists?(:pages, :date_end_int)
    add_column(:pages, :is_past, :boolean) unless column_exists?(:pages, :is_past)
  end
end
