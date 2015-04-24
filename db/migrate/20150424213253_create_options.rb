class CreateOptions < ActiveRecord::Migration
  def change
    create_table :options do |t|
      t.string :json_object
      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end
