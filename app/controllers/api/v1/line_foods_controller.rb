# --- ここから追加 ---
module Api
  module V1
    class LineFoodsController < ApplicationController
      before_action :set_food, only: %i[create]

      def create
        # 現在の仮オーダーの中に、追加オーダーの食品の店舗ではない店舗のオーダーがあるか
        if LineFood.active.other_restaurant(@ordered_food.restaurant.id).exists?
          # あれば、その店舗の名前と現在の店舗の名前と406 Not Acceptableをリターンする。
          return render json: {
            existing_restaurant: LineFood.other_restaurant(@ordered_food.restaurant.id).first.restaurant.name,
            new_restaurant: Food.find(params[:food_id]).restaurant.name,
          }, status: :not_acceptable
        end
          # なければ
        set_line_food(@ordered_food)

        if @line_food.save
          render json: {
            line_food: @line_food
          }, status: :created
        # エラーがあれば、レスポンスコード500系を返す。
        else
          render json: {}, status: :internal_server_error
        end
      end

      private

      def set_food
        @ordered_food = Food.find(params[:food_id])
      end

      # すでに同じ食品に対して仮注文をしていれば、その仮注文レコードの個数に今回分を追加する。
      def set_line_food(ordered_food)
        if ordered_food.line_food.present?
          @line_food = ordered_food.line_food
          @line_food.attributes = {
            count: ordered_food.line_food.count + params[:count],
            active: true
          }
        # 仮注文をしていなければ、仮注文レコードを作成する
        else
          @line_food = ordered_food.build_line_food(
            count: params[:count],
            restaurant: ordered_food.restaurant,
            active: true
          )
        end
      end
    end
  end
end