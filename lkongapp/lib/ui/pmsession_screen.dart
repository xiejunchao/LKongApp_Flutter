import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:lkongapp/models/lkong_jsons/lkong_json.dart';
import 'package:lkongapp/selectors/selectors.dart';
import 'package:lkongapp/ui/app_drawer.dart';
import 'package:lkongapp/ui/fetched_list.dart';
import 'package:lkongapp/ui/forum_story.dart';
import 'package:lkongapp/ui/items/forum_item.dart';
import 'package:lkongapp/ui/items/item_wrapper.dart';
import 'package:lkongapp/ui/items/message_items.dart';
import 'package:lkongapp/ui/modeled_app.dart';
import 'package:lkongapp/ui/tools/drawer_button.dart';
import 'package:lkongapp/ui/tools/icon_message.dart';
import 'package:lkongapp/ui/tools/item_handler.dart';
import 'package:lkongapp/utils/route.dart';
import 'package:lkongapp/utils/utils.dart';
import 'package:quiver/core.dart';
import 'package:redux/redux.dart';

import 'package:lkongapp/models/models.dart';
import 'package:lkongapp/actions/actions.dart';

import 'package:lkongapp/ui/connected_widget.dart';

class PMSessionScreen extends StatelessWidget {
  final int pmid;

  const PMSessionScreen({Key key, @required this.pmid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildConnectedWidget(context, PMSessionModel.fromIDAndStore(pmid),
        (viewModel) {
      return viewModel.buildConversationView(context);
    });
  }
}

class PMSessionModel extends FetchedListModel {
  final int uid;
  final int pmid;
  final Profile profile;
  final FetchList<PrivateMessage> session;
  final bool loading;
  final String lastError;
  final bool showDetailTime;

  static final _textController = TextEditingController();

  AppBar appBar(BuildContext context) => AppBar(
        title: GestureDetector(
          child: Text("${profile?.user?.username ?? ""}",
              style:
                  Theme.of(context).textTheme.title.apply(color: Colors.white)),
          onTap: () => scrollToTop(context),
        ),
      );

  @override
  bool operator ==(other) {
    return other is PMSessionModel &&
        session == other.session &&
        profile == other.profile &&
        loading == other.loading &&
        uid == other.uid &&
        pmid == other.pmid &&
        showDetailTime == other.showDetailTime &&
        lastError == other.lastError;
  }

  @override
  int get hashCode => hashObjects(
      [session, profile, loading, lastError, uid, pmid, showDetailTime]);

  PMSessionModel({
    @required this.uid,
    @required this.pmid,
    @required this.profile,
    @required this.session,
    @required this.showDetailTime,
    @required this.loading,
    @required this.lastError,
  });

  @override
  int get itemCount => session?.data?.length ?? 0;

  @override
  bool get reverse => true;

  @override
  APIRequest get fetchFromScratchRequest {
    final Completer<String> completer = Completer<String>();
    completer.future.then((error) {});
    return GetPMSessionNewRequest(completer, uid, pmid, 0, 0);
  }

  @override
  APIRequest get loadMoreRequest {
    if (session == null || session.nexttime == 0) {
      return null;
    }

    final Completer<String> completer = Completer<String>();
    completer.future.then((error) {});
    return GetPMSessionLoadMoreRequest(completer, uid, pmid, session.nexttime);
  }

  @override
  APIRequest get refreshRequest {
    if (session == null || session.current == 0) {
      return null;
    }

    final Completer<String> completer = Completer<String>();
    completer.future.then((error) {});
    return GetPMSessionRefreshRequest(completer, uid, pmid, session.current);
  }

  @override
  Future<Null> handleRefresh(BuildContext context) {
    final Completer<String> completer = Completer<String>();
    dispatchAction(context)(
        GetPMSessionRefreshRequest(completer, uid, pmid, session.current));
    return completer.future.then((_) {});
  }

  static Function fromIDAndStore(int pmid) {
    final func = (Store<AppState> store) {
      final userData = selectUserData(store);
      final uid = selectUID(store);

      return PMSessionModel(
        profile: store.state.uiState.content.profiles[pmid],
        uid: uid,
        loading: userData?.pmSession[pmid]?.loading ?? false,
        lastError: userData?.pmSession[pmid]?.lastError,
        pmid: pmid,
        session: userData?.pmSession[pmid],
        showDetailTime: selectSetting(store).showDetailTime,
      );
    };
    return func;
  }

  Widget createPMSessionItem(BuildContext context, PrivateMessage message) {
    return PMConciseItem(message);
  }

  void sendMessage(BuildContext context) {
    if (session.sending) {
      return;
    }

    final completer = Completer<String>();

    String message = _textController.text;
    print("Send Message: ${_textController.text}");
    _textController.clear();

    dispatchAction(context)(SendPMRequest(completer, uid, pmid, message));

    completer.future.then((error) {
      if (error != null) {
        String msg;
        msg = '消息发送失败' + ": $error";
        showToast(msg);
      }
    });
  }

  @override
  Widget headerForSection(BuildContext context, {int section}) {
    LKongAppTheme theme = LKModeledApp.modelOf(context).theme;
    return Container(
        color: theme.quoteBG,
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        alignment: Alignment.centerLeft,
        child: Row(children: <Widget>[
          Expanded(
            child: TextFormField(
              controller: _textController,
              scrollPadding: EdgeInsets.all(0),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.pageColor,
                contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1.0),
                    borderRadius: BorderRadius.circular(6.0)),
              ),
            ),
          ),
          SizedBox(
            width: 8.0,
          ),
          Container(
            height: 32,
            width: 64,
            child: session?.sending == true
                ? Center(
                    child: Container(
                        padding: EdgeInsets.all(4.0),
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator()))
                : FlatButton(
                    color: Colors.green[600],
                    child: Text("发送"),
                    onPressed: () {
                      sendMessage(context);
                    },
                  ),
          ),
        ]));
  }

  @override
  Widget Function(BuildContext, Widget) get wrapCell => wrapItemNoDivider;

  @override
  Widget createListItem(BuildContext context, int index) {
    BuiltList<PrivateMessage> messages = session.data;

    if (messages != null && index >= 0 && index < messages.length) {
      Widget item = createPMSessionItem(context, messages[index]);

      return wrapItemNoDivider(context, item);
    }
    return null;
  }

  @override
  bool get initLoaded => (session?.data?.length ?? 0) > 0;

  @override
  void listIsReady(BuildContext context) {}

  Widget buildConversationView(BuildContext context) {
    if (profile == null) {
      if (loading != true && lastError == null) {
        handleFetchUserInfo(context);
      }
    }

    return Scaffold(
      appBar: appBar(context),
      body: buildListView(context),
    );
  }

  void handleFetchUserInfo(BuildContext context) {
    if (pmid != null && pmid > 0) {
      dispatchAction(context)(UserInfoRequest(null, pmid));
    }
  }
}