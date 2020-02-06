import 'package:flutter/material.dart';
import 'package:flutter_learning/enums/action_type.dart';
import 'package:flutter_learning/enums/movement_type.dart';
import 'package:flutter_learning/enums/screen_type.dart';
import 'package:flutter_learning/enums/task_list_type.dart';
import 'package:flutter_learning/models/project.dart';
import 'package:flutter_learning/models/task.dart';
import 'package:flutter_learning/screens/task_details.dart';
import 'package:flutter_learning/screens/task_list_abs.dart';
import 'package:flutter_learning/utils/list_generator_helper.dart';

class TaskList extends TaskListAbs {
  
  final String appBarTitle;
  final Project project;
  
  TaskList(this.project, this.appBarTitle);

  @override
  State<StatefulWidget> createState() {
    return TaskListState(this.project, this.appBarTitle);
  }
}

class TaskListState extends TaskListAbsState {
  
  String appBarTitle;
  @override
  Project project;

  @override
  TaskListType type = TaskListType.InAProject;

  TaskListState(this.project, this.appBarTitle);
  
  @override
  Widget build(BuildContext context) {
    if (projectList == null) {
      projectList = List<Project>();
    }

    if (taskList == null) {
      taskList = List<Task>();
      updateTaskListView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle + " Tasks"),
      ),
      body: Form(
        key: formKey,
        child: getKeepLikeListView(context, this, taskList, taskCount, taskControllers, ScreenType.tasks)
      ),
      floatingActionButton: Builder(
        builder: (BuildContext context) {
          return FloatingActionButton(
            onPressed: () {
              debugPrint("FAB clicked");
              _addBlankTask(context);
              //navigateToTaskDetails(Task("", taskList.length, "", project.projectId, project.projectPosition), "Add Task");
            },
            tooltip: "Add Task",
            child: Icon(Icons.add),
            );
          },
        )
      );
  }

  void _addBlankTask(BuildContext context) {
    taskList.add(Task("", taskList.length, "", project.projectId, project.projectPosition));
    save(context, ActionType.add, taskList.length - 1);
  }

  @override
  void reorder(BuildContext context, Task task, MovementType movementType) async {
    int result = await databaseHelper.reorderTask(task.projectId, task.taskPosition, movementType);
    if (result != 0) {
      showSnackBar(context, "Task moved successfully");
      updateTaskListView();
    }
  }

  void navigateToTaskDetails(Task note, String title) async {
    bool result = await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return TaskDetails(note, title);
    }));

    if (result) {
      updateTaskListView();
    }
  }
}