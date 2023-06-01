# --- ここから追加 ---
module Api
  module V1
    class LineFoodsController < ApplicationController
      before_action :set_food, only: %i[create replace]

      def index
        line_foods = LineFood.active
        if line_foods.exists?
          render json: {
            line_food_ids: line_foods.map { |line_food| line_food.id },
            restaurant: line_foods[0].restaurant,
            # ブロック内の式を計算後に加算されます。
            count: line_foods.sum { |line_food| line_food[:count] },
            amount: line_foods.sum { |line_food| line_food.total_amount },
          }, status: :ok
        else
          # 空データとstatus: :no_contentを返すことにします。
          # ステータスコードは「リクエストは成功したが、空データ」として204を返す
          render json: {}, status: :no_content
        end
      end

      def create
        # 現在の仮注文の中に、追加注文の食品の店舗ではない店舗の注文があるか
        if LineFood.active.other_restaurant(@ordered_food.restaurant.id).exists?
          # あれば、その店舗の名前と追加注文の店舗の名前を406 Not Acceptableでリターンする。
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

      # 既にある古い仮注文を論理削除(activeというカラムにfalseを入れるなどして、
      # データを非活性の状態にすること)し、新しいレコードを作成する
      def replace
        LineFood.active.other_restaurant(@ordered_food.restaurant.id).each do |line_food|
          line_food.update_attribute(:active, false)
        end

        set_line_food(@ordered_food)

        if @line_food.save
          render json: {
            line_food: @line_food
          }, status: :created
        else
          render json: {}, status: :internal_server_error
        end
      end

      private

      def set_food
        @ordered_food = Food.find(params[:food_id])
      end

      # 引数で受け取った食品を仮注文しているか確認
      def set_line_food(ordered_food)
        # すでに仮注文していれば、
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