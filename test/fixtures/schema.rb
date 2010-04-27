ActiveRecord::Schema.define do
  create_table "async_jobs", :force => true do |t|
    t.string :worker, :null => false
    t.text :job_data
    t.text :job_results
    t.string :status, :null => false
    t.datetime :run_at
    t.timestamps
  end
end
