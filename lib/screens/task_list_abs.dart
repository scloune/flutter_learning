import 'package:flutter/material.dart';
import 'package:priority_keeper/enums/action_type.dart';
import 'package:priority_keeper/enums/checked_item_state.dart';
import 'package:priority_keeper/enums/task_list_type.dart';
import 'package:priority_keeper/models/project.dart';
import 'package:priority_keeper/models/task.dart';
import 'package:priority_keeper/screens/actions_interface.dart';
import 'package:priority_keeper/utils/database_helper.dart';
import 'package:priority_keeper/utils/screen_with_snackbar.dart';
import 'package:priority_keeper/utils/task_action_helper.dart';
import 'package:sqflite/sqlite_api.dart';

abstract class TaskListAbs extends StatefulWidget {}

abstract class TaskListAbsState extends State<TaskListAbs>
    with ActionsInterface<Task>, ScreenWithSnackbar {
  @protected
  DatabaseHelper databaseHelper = DatabaseHelper();
  @protected
  List<Project> projectList;
  @protected
  int projectCount = 0;
  @protected
  Project project;
  @protected
  List<Task> taskList;
  @protected
  int taskCount = 0;
  @protected
  List<TextEditingController> taskControllers;
  @protected
  List<Task> checkedTaskList;
  @protected
  int checkedTaskCount = 0;
  @protected
  List<TextEditingController> checkedTaskControllers;
  @protected
  var formKey = GlobalKey<FormState>();
  @protected
  TaskListType type;

  @override
  void updateTitle(CheckedItemState state, int position) {
    if (state.isChecked) {
      checkedTaskList[position].title = checkedTaskControllers[position].text;
    } else {
      taskList[position].title = taskControllers[position].text;
    }
  }

  @override
  void delete(BuildContext context, Task task, CheckedItemState state) async {
    int result = await databaseHelper.deleteTask(
        state.isChecked, task.taskId, task.projectId);
    if (result != 0) {
      showSnackBar(context, "Task deleted successfully");
      state.isChecked ? updateCheckedListView() : updateUncheckedListView();
    }
  }

  @override
  void onCheckboxChanged(BuildContext context, CheckedItemState state,
      int position, bool completed) {
    if (state.isChecked) {
      checkedTaskList[position].setCompleted(completed);
    } else {
      taskList[position].setCompleted(completed);
    }

    save(context, state, completed ? ActionType.check : ActionType.uncheck,
        position);
  }

  @override
  void save(BuildContext context, CheckedItemState state, ActionType action,
      int position) async {
    int result = await TaskActionHelper.saveTaskToDatabase(
        context,
        formKey,
        state.isChecked ? checkedTaskList[position] : taskList[position],
        databaseHelper);

    if (action == ActionType.check || action == ActionType.uncheck) {
      result *= await databaseHelper.updateTaskPositionsAfterOnCheckedChanged(
          state.isChecked
              ? checkedTaskList[position].projectId
              : taskList[position].projectId,
          action == ActionType.check);
    }

    String message = "";
    if (result != 0) {
      state.isChecked ? updateCheckedListView() : updateUncheckedListView();

      if (action == ActionType.updateTitle) {
        message = "Title updated successfully";
      } else if (action == ActionType.check) {
        message = "Task done";
        updateTheOppositeListView(state);
      } else if (action == ActionType.uncheck) {
        message = "Task moved to active tasks";
        updateTheOppositeListView(state);
      } else if (action == ActionType.add) {
        message = "Task saved successfully";
      }
    } else {
      if (action == ActionType.updateTitle) {
        message = "Problem updating the title";
      } else if (action == ActionType.check) {
        message = "Problem checking the task";
      } else if (action == ActionType.uncheck) {
        message = "Problem unchecking the task";
      } else if (action == ActionType.add) {
        message = "Problem saving the task";
      }
    }

    if (message.isNotEmpty) {
      showSnackBar(context, message);
    }
  }

  @override
  void updateUncheckedListView() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      Future<List<Task>> taskListFuture = databaseHelper.getTaskList(
          type,
          CheckedItemState.unchecked.isChecked,
          type == TaskListType.InAProject ? project.projectId : -1);
      taskListFuture.then((taskList) {
        setState(() {
          this.taskList = taskList;
          this.taskControllers = List<TextEditingController>();

          this.taskCount = taskList.length;
          for (int i = 0; i < this.taskList.length; i++) {
            this.taskControllers.add(TextEditingController(
                  text: taskList[i].title != null ? taskList[i].title : "",
                ));
          }
        });
      });
    });
  }
}
