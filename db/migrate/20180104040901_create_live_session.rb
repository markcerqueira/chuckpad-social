class CreateLiveSession < ActiveRecord::Migration[5.1]
    def up
      create_table :live_sessions do |t|
        t.string :session_guid

        t.integer :creator_id

        t.string :title, :null => false

        # Used to filter out "inactive" sessions: 0 -> active, 1 -> closed
        t.integer :state, :default => 0

        t.integer :occupancy, :default => 0

        t.integer :session_type

        # session_data represents arbitrary meta-data associated with the session
        t.binary :session_data

        t.datetime :created_at
        t.datetime :last_active
      end
    end

    def down
      drop_table :live_sessions
    end
end
