class Order < ApplicationRecord
  has_many :line_foods
  validates :total_price, numericality: { greater_than: 0 }

  # トランザクションで仮注文の更新（論理削除）と本注文の保存を一括で行う。
  def save_with_update_line_foods(line_foods)
    ActiveRecord::Base.transaction do
      line_foods.each do |line_food|
        line_food.update!(active: false, order: self)
      end
      self.save!
    end
  end
end 