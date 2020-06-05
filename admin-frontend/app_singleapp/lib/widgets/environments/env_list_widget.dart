
import 'package:app_singleapp/utils/custom_cursor.dart';
import 'package:app_singleapp/widgets/common/fh_alert_dialog.dart';
import 'package:app_singleapp/widgets/common/fh_delete_thing.dart';
import 'package:app_singleapp/widgets/common/fh_info_card.dart';
import 'package:app_singleapp/widgets/common/fh_reorderable_list_view.dart';
import 'package:bloc_provider/bloc_provider.dart';
import 'package:app_singleapp/widgets/apps/manage_app_bloc.dart';
import 'package:app_singleapp/widgets/common/FHFlatButton.dart';
import 'package:app_singleapp/widgets/common/fh_icon_button.dart';
import 'package:app_singleapp/widgets/common/fh_icon_text_button.dart';
import 'package:flutter/material.dart';
import 'package:mrapi/api.dart';
import 'package:openapi_dart_common/openapi.dart';
import 'package:app_singleapp/widgets/common/fh_outline_button.dart';

class EnvListWidget extends StatefulWidget {
  @override
  _EnvListState createState() => _EnvListState();
}

class _EnvListState extends State<EnvListWidget> {
  List<Environment> _environments;

  @override
  Widget build(BuildContext context) {
    ManageAppBloc bloc = BlocProvider.of(context);

    return StreamBuilder<List<Environment>>(
        stream: bloc.environmentsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Container();
          }
          //_environments = snapshot.data.reversed.toList();
          _environments = _sortEnvironments(snapshot.data);

          return Container(
            color: Theme.of(context).highlightColor,
            //height:(snapshot.data.length*50).toDouble(),
            height: 500.0,
            child: FHReorderableListView(
              onReorder: (int oldIndex, int newIndex) {
                _reorderEnvironments(oldIndex, newIndex, bloc);
              },
              children: <Widget>[
                for (Environment env in _environments)
                  _EnvWidget(env: env, bloc: bloc, key: Key(env.id))
              ],
            ),
          );
        });
  }

  List<Environment> _sortEnvironments(List<Environment> originalList,
      {String parentId = "", List<Environment> sortedList}) {
    if (sortedList == null) {
      sortedList = [];
    }
    originalList.forEach((env) {
      if (env.priorEnvironmentId == null && parentId == "") {
        sortedList.insert(0, env);
        _sortEnvironments(originalList,
            parentId: env.id, sortedList: sortedList);
      } else if (env.priorEnvironmentId == parentId) {
        sortedList.add(env);
        _sortEnvironments(originalList,
            parentId: env.id, sortedList: sortedList);
      }
    });
    return sortedList;
  }

  _reorderEnvironments(int oldIndex, int newIndex, ManageAppBloc bloc) async {
    setState(() {
      // These two lines are workarounds for ReorderableListView problems
      if (newIndex > _environments.length) newIndex = _environments.length;
      if (oldIndex < newIndex) newIndex--;

      final Environment item = _environments[oldIndex];
      _environments.remove(item);
      _environments.insert(newIndex, item);

      // shuffle the previousIds and save the polar bears
      if (newIndex > 0) {
        _environments[newIndex].priorEnvironmentId =
            _environments[newIndex - 1].id;
      }
      if (newIndex < _environments.length - 1) {
        _environments[newIndex + 1].priorEnvironmentId = item.id;
      }
      if (oldIndex < _environments.length - 1 && oldIndex > 0) {
        _environments[oldIndex].priorEnvironmentId =
            _environments[oldIndex - 1].id;
      }
      if (newIndex < oldIndex && oldIndex < _environments.length - 1) {
        _environments[oldIndex + 1].priorEnvironmentId =
            _environments[oldIndex].id;
      }
    });
    _environments[0].priorEnvironmentId =
        null; // first environment should never have a parent
    await bloc.updateEnvs(bloc.appId, _environments);
    bloc.mrClient.addSnackbar(Text("Environment order updated!"));
  }

  List<Environment> swapPreviousIds(oldPid, newPid) {
    List<Environment> updatedEnvs = [];
    _environments.forEach((env) {
      if (env.priorEnvironmentId == oldPid) {
        env.priorEnvironmentId = newPid;
        updatedEnvs.add(env);
      }
    });
    return updatedEnvs;
  }
}

class _EnvWidget extends StatelessWidget {
  final Environment env;
  final ManageAppBloc bloc;
  final Key key;

  const _EnvWidget(
      {@required this.key, @required this.env, @required this.bloc})
      : assert(env != null),
        assert(bloc != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final BorderSide bs = BorderSide(color: Theme.of(context).dividerColor);

    return Container(
      padding: const EdgeInsets.fromLTRB(30, 5, 30, 5),
      decoration: BoxDecoration(
          color: Colors.white, border: Border(bottom: bs, left: bs, right: bs)),
      child: Container(
        height: 50,
        child: CustomCursor(
          cursorStyle: "move",
          child: Row(
            children: <Widget>[
              Container(
                  padding: EdgeInsets.only(right: 30),
                  child: Icon(
                    Icons.menu,
                    color: Colors.grey,
                  )),
              Row(
                children: <Widget>[
                  Text("${env.name}"),
                  Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child:
                      env.production ? _ProductionEnvironmentIndicatorWidget() : _NonProductionEnvironmentIndicatorWidget()
                  ),
                ],
              ),
              Expanded(child: Container()),
              bloc.mrClient.isPortfolioOrSuperAdmin(bloc.application.portfolioId)
                  ? _adminFunctions(context)
                  : Container()
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminFunctions(BuildContext context) {
    return Row(children: [
      FHIconButton(
          icon: Icon(Icons.edit),
          onPressed: () => bloc.mrClient.addOverlay((BuildContext context) =>
              EnvUpdateDialogWidget(bloc: bloc, env: env))),
      FHIconButton(
          icon: Icon(Icons.delete),
          onPressed: () => bloc.mrClient.addOverlay((BuildContext context) {
                return EnvDeleteDialogWidget(
                  env: env,
                  bloc: bloc,
                );
              })),
    ]);
  }
}

class _ProductionEnvironmentIndicatorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Production environment',
      child: Container(
        width: 24.0,
        height: 24.0,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle
        ),
        child: Center(child: Text('P', style: TextStyle(color: Colors.white, fontSize: 18.0))),
      ),
    );
  }
}

class _NonProductionEnvironmentIndicatorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.0,
      height: 24.0,
    );
  }

}


class EnvDeleteDialogWidget extends StatelessWidget {
  final Environment env;
  final ManageAppBloc bloc;

  const EnvDeleteDialogWidget({Key key, @required this.bloc, this.env})
      : assert(env != null),
        assert(bloc != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // is there only one environment or are we the last one in the chain (no other has us as a prior environment)
    return FHDeleteThingWarningWidget(
      bloc: bloc.mrClient,
      extraWarning: env.production,
      wholeWarning: env.production ? "The environment `${env.name}` is your production environment, are you sure you wish to remove it?" : null,
      thing: env.production ? null : "environment '${env.name}'",
      deleteSelected: () async {
        bool success = await bloc.deleteEnv(env.id);
        if (success) {
          bloc.mrClient
              .addSnackbar(Text("Environment '${env.name}' deleted!"));
        } else {
          bloc.mrClient.customError(
              messageTitle: "Couldn't delete environment ${env.name}");
        }
        return success;
      },
    );
  }
}

class EnvUpdateDialogWidget extends StatefulWidget {
  final Environment env;
  final ManageAppBloc bloc;

  const EnvUpdateDialogWidget({
    Key key,
    @required this.bloc,
    this.env,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EnvUpdateDialogWidgetState();
  }
}

class _EnvUpdateDialogWidgetState extends State<EnvUpdateDialogWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _envName = TextEditingController();
  bool isUpdate = false;
  bool _isProduction = false;

  @override
  void initState() {
    super.initState();
    if (widget.env != null) {
      _envName.text = widget.env.name;
      isUpdate = true;
      _isProduction = widget.env.production;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: FHAlertDialog(
        title: Text(
            widget.env == null ? 'Create new environment' : 'Edit environment'),
        content: Container(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                  controller: _envName,
                  decoration: InputDecoration(labelText: "Environment name"),
                  validator: ((v) {
                    if (v.isEmpty) {
                      return "Please enter an environment name";
                    }
                    if (v.length < 2) {
                      return "Environment name needs to be at least 2 characters long";
                    }
                    return null;
                  })),
              CheckboxListTile(
                title: Text('Production Environment'),
                value: _isProduction,
                onChanged: (bool val) {
                  setState(() {
                    _isProduction = val;
                  });
                },
              )
            ],
          ),
        ),
        actions: <Widget>[
          FHOutlineButton(
            title: "Cancel",
            onPressed: () {
              widget.bloc.mrClient.removeOverlay();
            },
          ),
          FHFlatButton(
              title: isUpdate ? "Update" : "Create",
              onPressed: (() async {
                if (_formKey.currentState.validate()) {
                  try {
                    if (isUpdate) {
                      await widget.bloc.updateEnv(widget.env..production = _isProduction, _envName.text);
                      widget.bloc.mrClient.removeOverlay();
                      widget.bloc.mrClient.addSnackbar(
                          Text("Environment ${_envName.text} updated!"));
                    } else {
                      await widget.bloc.createEnv(_envName.text, _isProduction);
                      widget.bloc.mrClient.removeOverlay();
                      widget.bloc.mrClient.addSnackbar(
                          Text("Environment ${_envName.text} created!"));
                    }
                  } catch (e, s) {
                    if (e is ApiException && e.code == 409) {
                      widget.bloc.mrClient.customError(
                          messageTitle:
                              "Environment with name ${_envName.text} already exists");
                    } else {
                      widget.bloc.mrClient.dialogError(e, s);
                    }
                  }
                }
              }))
        ],
      ),
    );
  }
}

Widget AddEnvWidget(BuildContext context, ManageAppBloc bloc) {
  final BorderSide bs = BorderSide(color: Theme.of(context).dividerColor);
  return Column(children: <Widget>[
    Container(
        padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(bottom: bs, left: bs, right: bs, top: bs)),
        child: Row(
          children: <Widget>[
            if (bloc.mrClient.isPortfolioOrSuperAdmin(bloc.application.portfolioId))
              Container(
                  padding: EdgeInsets.only(left: 30),
                  child: FHIconTextButton(
                    iconData: Icons.add,
                    keepCase: true,
                    label: 'Create new environment',
                    onPressed: () =>
                        bloc.mrClient.addOverlay((BuildContext context) {
                      return EnvUpdateDialogWidget(
                        bloc: bloc,
                      );
                    }),
                  )),
            Container(
                padding: EdgeInsets.only(left: 20),
                child: FHInfoCardWidget(
                    message:
                        "Tip: Ordering your environments, showing the path to production (top to bottom), helps your teams see their changes follow this path.")),
          ],
        ))
  ]);
}
