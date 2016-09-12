require 'sequel'
require 'pry'

class SequelPersistence

  def initialize(logger)
    @db = Sequel.connect("postgres://localhost/todos")
    @db.loggers << logger
    #@session = session
    #@session[:lists] ||= []
  end

  def find_list(id)
    all_lists.where(lists__id: id).first
  end

  def all_lists
    #sql = "select * from lists"
    @db[:lists].left_join(:todos, list_id: :id).
    select_all(:lists).
    select_append do
      [count(todos__id).as(todos_count),
      count(nullif(todos__completed,true)).as(todos_remaining_count)]
    end.
    group(:lists__id).
    order(:lists__name)
  end



  def create_new_list(list_name)
    @db[:lists].insert(name: list_name)
  end

  def delete_list(id)
    @db[:todos].where(list_id: id).delete
    @db[:lists].where(id: id).delete
  end

  def update_list_name(id, list_name)
    @db[:lists].where(id: id).update(name: list_name)
  end

  def create_new_todo(list_id,todo_name)
    @db[:todos].insert(name: todo_name, list_id: list_id)
  end

  def delete_todo_from_list(list_id,todo_id)
    @db[:todos].where(list_id: list_id, id: todo_id).delete
  end

  def update_todo_status(list_id,todo_id,is_completed)
    @db[:todos].where(id: todo_id, list_id: list_id).update(completed: is_completed)
  end

  def mark_all_todos_complete(list_id)
    @db[:todos].where(list_id: list_id).update(completed: true)
  end

  def find_todos_for_list(list_id)
    @db[:todos].where(list_id: list_id)
  end

end
