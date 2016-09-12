require 'pg'
require 'pry'

class DatabasePersistence

  def initialize(logger)
    @db = PG::Connection.new(dbname: "todos")
    @logger = logger
    #@session = session
    #@session[:lists] ||= []
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement,params)
  end

  def find_list(id)
    #sql = "select * from lists where id = $1"
    sql = "select lists.*, count(todos.id) as todos_count,
     count(nullif(todos.completed,true)) as todos_remaining_count
     from lists left join todos on todos.list_id = lists.id
     where lists.id = $1
     group by lists.id
     order by lists.name"
    result = query(sql,id)
    tuple = result.first
    #list_id = tuple["id"].to_i
    tuple_to_list_hash(tuple)
    #todos = find_todos_for_list(list_id)
    #@session[:lists].find{ |list| list[:id] == id }
  end

  def all_lists
    #sql = "select * from lists"
    sql = "select lists.*, count(todos.id) as todos_count,
     count(nullif(todos.completed,true)) as todos_remaining_count
     from lists left join todos on todos.list_id = lists.id group by lists.id
     order by lists.name"
    result = query(sql)

    result.map do |tuple|
      #list_id = tuple["id"].to_i
      #todos = find_todos_for_list(list_id)
      tuple_to_list_hash(tuple)
    end
    #@session[:lists]
  end



  def create_new_list(list_name)
    sql = "insert into lists (name) values ($1)"
    query(sql,list_name)
    #id = next_element_id(@session[:lists])
    #@session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    sql = "delete from lists where id=$1"
    sql2 = "delete from todos where list_id = $1"
    query(sql2,id)
    query(sql,id)
    #@session[:lists].reject! { |list| list[:id] == id }
  end

  def update_list_name(id, list_name)
    sql = "update lists set name=$1 where id = $2"
    query(sql,list_name,id)
    #list = find_list(id)
    #list[:name] = list_name
  end

  def create_new_todo(list_id,todo_name)
    sql = "insert into todos (name,list_id) values ($1, $2)"
    query(sql,todo_name,list_id)
    #list = find_list(list_id)
    #id = next_element_id(list[:todos])
    #list[:todos] << { id: id, name: todo_name, completed: false }
  end

  def delete_todo_from_list(list_id,todo_id)
    sql = "delete from todos where list_id = $1 and id = $2"
    query(sql,list_id,todo_id)
    #list = find_list(list_id)
    #list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  def update_todo_status(list_id,todo_id,is_completed)
    sql = "update todos set completed = $1, where id = $2 and list_id = $3"
    query(sql,is_completed,todo_id,list_id)
    #list = find_list(list_id)
    #todo = list[:todos].find { |todo| todo[:id] == todo_id }
    #todo[:completed] = is_completed
  end

  def mark_all_todos_complete(list_id)
    sql = "update todos set completed = true where list_id = $1"
    query(sql,list_id)
    #list = find_list(list_id)
    #list[:todos].each do |todo|
      #todo[:completed] = true
  end


  def find_todos_for_list(list_id)
    todo_sql = "select * from todos where list_id = $1"
    todos_result = query(todo_sql,list_id)
    todos_result.map do |todo_tuple|
      {id: todo_tuple["id"].to_i, name: todo_tuple["name"], completed: todo_tuple["completed"] == 't'}
    end
  end
private
  def tuple_to_list_hash(tuple)
    {id: tuple["id"].to_i, name: tuple["name"], todos_count: tuple["todos_count"].to_i, todos_remaining_count: tuple["todos_remaining_count"].to_i}
  end
end
