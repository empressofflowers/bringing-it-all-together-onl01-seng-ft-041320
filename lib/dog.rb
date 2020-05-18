class Dog
    attr_accessor :name, :breed
    attr_reader :id

    def initialize id:nil, name:, breed:
        @id = id
        @name = name
        @breed = breed
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs(
            id INTERGER PRIMARY KEY,
            name TEXT,
            breed TEXT)
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = "DROP TABLE IF EXISTS dogs"
        DB[:conn].execute(sql)
    end

    def self.new_from_db row
        id = row[0]
        name = row[1]
        breed = row[2]
        self.new(id: id, name: name, breed: breed)
    end

    def self.find_by_name name
        sql = "SELECT * FROM dogs WHERE name = ?"
        DB[:conn].execute(sql, name).map {|row| self.new_from_db(row)}.first
    end

    def update
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

    def save
        if self.id
            self.update
        else
            sql = <<-SQL
                INSERT INTO dogs (name, breed)
                VALUES (?, ?)
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
            self
        end
    end

    def self.create name:, breed:
        dog = Dog.new(name: name, breed: breed)
        dog.save
        dog
    end

    def self.find_by_id id
        sql = "SELECT * FROM dogs WHERE id = ? LIMIT 1"
        DB[:conn].execute(sql,id).map {|row| self.new_from_db(row)}.first
    end

    def self.find_or_create_by(name:,breed:)
        sql = "SELECT * FROM dogs WHERE name = ? AND breed = ? LIMIT 1"
        dog = DB[:conn].execute(sql,name,breed)

        if dog.empty?
            dog = self.create({name: name, breed: breed})
        else
            new_dog = dog[0]
            dog = self.new(id: new_dog[0], name: new_dog[1], breed: new_dog[2])
        end
        dog
    end
end