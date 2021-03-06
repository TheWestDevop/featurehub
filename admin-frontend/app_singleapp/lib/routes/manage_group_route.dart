import 'package:app_singleapp/third_party/chips_input.dart';
import 'package:app_singleapp/widgets/common/FHFlatButton.dart';
import 'package:app_singleapp/widgets/common/decorations/fh_page_divider.dart';
import 'package:app_singleapp/widgets/common/fh_alert_dialog.dart';
import 'package:app_singleapp/widgets/common/fh_flat_button_transparent.dart';
import 'package:app_singleapp/widgets/common/fh_header.dart';
import 'package:app_singleapp/widgets/common/fh_icon_button.dart';
import 'package:app_singleapp/widgets/common/fh_icon_text_button.dart';
import 'package:app_singleapp/widgets/group/group_bloc.dart';
import 'package:app_singleapp/widgets/group/group_update_widget.dart';
import 'package:bloc_provider/bloc_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mrapi/api.dart';

/// Every user has access to portfolios, they can only see the ones they have access to
/// and their access will be limited based on whether they are a site admin.
class ManageGroupRoute extends StatefulWidget {
  @override
  _ManageGroupRouteState createState() => _ManageGroupRouteState();
}

class _ManageGroupRouteState extends State<ManageGroupRoute> {
  GroupBloc bloc;

  @override
  void initState() {
    bloc = BlocProvider.of<GroupBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 30, 10),
            child: FHHeader(
              title: 'Manage group members',
              children: [],
            )),
        FHPageDivider(),
        Row(
          children: <Widget>[
            Flexible(
              flex: 1,
              child: StreamBuilder<List<Group>>(
                  stream:
                      bloc.mrClient.streamValley.currentPortfolioGroupsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                          padding: EdgeInsets.all(8),
                          child: Text('Fetching Groups...'));
                    } else {
                      return Container(
                        padding: EdgeInsets.only(top: 24, left: 8),
                        child: _groupsDropdown(snapshot.data, bloc),
                      );
                    }
                  }),
            ),
            Flexible(
              flex: 2,
              child: bloc.mrClient
                      .isPortfolioOrSuperAdmin(bloc.mrClient.currentPid)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 24.0, left: 16),
                      child: Row(
                        children: [
                          Flexible(flex: 1, child: _getAdminActions(bloc)),
                          Flexible(
                            flex: 4,
                            child: Container(
                                child: FHIconTextButton(
                              iconData: Icons.add,
                              keepCase: true,
                              label: 'Create new group',
                              onPressed: () => bloc.mrClient
                                  .addOverlay((BuildContext context) {
                                return GroupUpdateDialogWidget(
                                  bloc: bloc,
                                );
                              }),
                            )),
                          ),
                        ],
                      ),
                    )
                  : Container(),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: StreamBuilder<Group>(
              stream: bloc.groupLoaded,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _filterRow(context, bloc, snapshot.data),
                      for (Person p in snapshot.data.members)
                        MemberWidget(
                          group: snapshot.data,
                          member: p,
                          bloc: bloc,
                        )
                    ],
                  );
                } else {
                  return Container();
                }
              }),
        ),
      ],
    );
  }

  Widget _getAdminActions(GroupBloc bloc) {
    return Row(children: <Widget>[
      StreamBuilder<Group>(
          stream: bloc.groupLoaded,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Row(children: <Widget>[
                FHIconButton(
                    icon:
                        Icon(Icons.edit, color: Theme.of(context).buttonColor),
                    onPressed: () => bloc.mrClient.addOverlay(
                        (BuildContext context) => GroupUpdateDialogWidget(
                              bloc: bloc,
                              group: bloc.group,
                            ))),
                //hide the delete button for Admin groups
                snapshot.data.admin
                    ? Container()
                    : FHIconButton(
                        icon: Icon(Icons.delete,
                            color: Theme.of(context).buttonColor),
                        onPressed: () =>
                            bloc.mrClient.addOverlay((BuildContext context) {
                              return GroupDeleteDialogWidget(
                                bloc: bloc,
                                group: bloc.group,
                              );
                            }))
              ]);
            } else {
              return Container();
            }
          }),
    ]);
  }

  Widget _groupsDropdown(List<Group> groups, GroupBloc bloc) {
    return groups == null || groups.isEmpty
        ? Text('No groups found in the portfolio')
        : Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  'Portfolio groups',
                  style: Theme.of(context).textTheme.caption,
                ),
                InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 300),
                    child: DropdownButton(
                      icon: Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 24,
                        ),
                      ),
                      isDense: true,
                      isExpanded: true,
                      items: groups.map((Group group) {
                        return DropdownMenuItem<String>(
                            value: group.id,
                            child: Text(group.name,
                                style: Theme.of(context).textTheme.bodyText2,
                                overflow: TextOverflow.ellipsis));
                      }).toList(),
                      hint: Text(
                        'Select group',
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                      onChanged: (value) {
                        setState(() {
                          bloc.getGroup(value);
                          bloc.groupId = value;
                        });
                      },
                      value: bloc.groupId,
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _filterRow(BuildContext context, GroupBloc bloc, Group group) {
    final bs = BorderSide(color: Theme.of(context).dividerColor);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 30, 10),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(bottom: bs, left: bs, right: bs, top: bs)),
      child: Row(
        children: <Widget>[
          Container(
            child: bloc.mrClient.isPortfolioOrSuperAdmin(group.portfolioId)
                ? FHIconTextButton(
                    iconData: Icons.add,
                    label: 'Add members',
                    onPressed: () =>
                        bloc.mrClient.addOverlay((BuildContext context) {
                      return AddMembersDialogWidget(
                        bloc: bloc,
                        group: group,
                      );
                    }),
                    keepCase: true,
                  )
                : Container(),
          )
        ],
      ),
    );
  }
}

class MemberWidget extends StatelessWidget {
  final Person member;
  final Group group;
  final GroupBloc bloc;

  const MemberWidget(
      {Key key, @required this.group, @required this.bloc, this.member})
      : assert(group != null),
        assert(bloc != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final bs = BorderSide(color: Theme.of(context).dividerColor);

    return Container(
      padding: const EdgeInsets.fromLTRB(30, 5, 30, 5),
      decoration: BoxDecoration(
          color: Colors.white, border: Border(bottom: bs, left: bs, right: bs)),
      child: Row(
        children: <Widget>[
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${member.name}'),
            ],
          )),
          if (bloc.mrClient.isPortfolioOrSuperAdmin(group.portfolioId))
            FHFlatButtonTransparent(
              title: 'Remove from group',
              keepCase: true,
              onPressed: () {
                try {
                  bloc.removeFromGroup(group, member);
                  bloc.mrClient.addSnackbar(Text(
                      "'${member.name}' removed from group '${group.name}'"));
                } catch (e, s) {
                  bloc.mrClient.dialogError(e, s);
                }
              },
            ),
        ],
      ),
    );
  }
}

class AddMembersDialogWidget extends StatefulWidget {
  final Group group;
  final GroupBloc bloc;

  const AddMembersDialogWidget(
      {Key key, @required this.bloc, @required this.group})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddMembersDialogWidgetState();
  }
}

class _AddMembersDialogWidgetState extends State<AddMembersDialogWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final membersToAdd = <Person>[];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: FHAlertDialog(
        title: Text('Add members to group ' + widget.group.name),
        content: Container(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[membersChips(widget.bloc)],
          ),
        ),
        actions: <Widget>[
          FHFlatButtonTransparent(
            title: 'Cancel',
            keepCase: true,
            onPressed: () {
              widget.bloc.mrClient.removeOverlay();
            },
          ),
          FHFlatButton(
              title: 'Add to group',
              keepCase: true,
              onPressed: () async {
                final group = widget.group;
                group.members = List.from(group.members)..addAll(membersToAdd);
                // remove duplicates
                group.members = group.members.toSet().toList();
                final success = await widget.bloc.updateGroup(group);
                if (success) {
                  widget.bloc.mrClient.removeOverlay();
                  widget.bloc.mrClient
                      .addSnackbar(Text("Group '${group.name}' updated!"));
                }
              })
        ],
      ),
    );
  }

  Widget membersChips(GroupBloc bloc) {
    return ChipsInput(
      initialValue: [],
      // none, but we could
      decoration:
          InputDecoration(labelText: 'Enter members to add to group...'),
      findSuggestions: (String query) async {
        if (query.isNotEmpty) {
          var sp = await bloc.mrClient.personServiceApi
              .findPeople(filter: query, order: SortOrder.ASC);
          return sp.people;
        }
        return const <Person>[];
      },
      onChanged: (data) {
        data.forEach((person) {
          person = person as Person;
          membersToAdd.add(person);
        });
      },
      // when we need to build a chip because it has been selected, this is what is used
      // it can include an image, so we should perhaps consider this?
      chipBuilder: (context, state, p) {
        final person = p as Person;
        return InputChip(
          key: ObjectKey(p),
          label: Text('${person.name} (${person.email})'),
          onDeleted: () => state.deleteChip(p),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
      // this is what is used to show the suggestions.
      suggestionBuilder: (context, state, p) {
        final person = p as Person;
        return ListTile(
          key: ObjectKey(p),
          title: Text(person.name),
          subtitle: Text(person.email),
          onTap: () => state.selectSuggestion(p),
        );
      },
    );
  }
}
