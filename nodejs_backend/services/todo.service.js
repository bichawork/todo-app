const ToDoModel = require("../models/todo.model");

class ToDoService {
  static async createToDo(userId, title, description) {
    try {
      const createToDo = new ToDoModel({ userId, title, description });
      return await createToDo.save();
    } catch (error) {
      throw new Error(`Failed to create ToDo: ${error.message}`);
    }
  }

  static async getUserToDoList(userId) {
    try {
      const todoList = await ToDoModel.find({ userId });
      return todoList;
    } catch (error) {
      throw new Error(`Failed to fetch ToDo list: ${error.message}`);
    }
  }

  static async deleteToDo(id) {
    try {
      const deleted = await ToDoModel.findByIdAndDelete(id);
      if (!deleted) {
        throw new Error("ToDo not found");
      }
      return deleted;
    } catch (error) {
      throw new Error(`Failed to delete ToDo: ${error.message}`);
    }
  }
  static async updateToDo({ id, title, description }) {
    try {
      const updatedTodo = await ToDoModel.findByIdAndUpdate(
        id,
        { title, description, updatedAt: Date.now() },
        { new: true, runValidators: true }
      );
      if (!updatedTodo) {
        throw new Error('Todo not found');
      }
      return updatedTodo;
    } catch (error) {
      throw new Error(`Failed to update ToDo: ${error.message}`);
    }
  };
}



module.exports = ToDoService;