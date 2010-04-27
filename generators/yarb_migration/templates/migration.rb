class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table :async_jobs, :force => true do |t|
      t.string :worker, :null => false
      t.text :job_data
      t.text :job_results
      t.string :status, :null => false
      t.datetime :run_at
      t.timestamps
    end
    add_index :async_jobs, :status
  end

  def self.down
    drop_table :async_jobs
  end
end
