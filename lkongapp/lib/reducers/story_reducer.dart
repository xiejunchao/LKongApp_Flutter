import 'package:built_collection/built_collection.dart';
import 'package:lkongapp/models/lkong_jsons/story_result.dart';
import 'package:lkongapp/utils/utils.dart';
import 'package:redux/redux.dart';

import 'package:lkongapp/actions/actions.dart';
import 'package:lkongapp/models/models.dart';

import 'fetchlist_reducer.dart';

final storyContentsReducer = combineReducers<BuiltMap<int, StoryPageList>>([
  TypedReducer<BuiltMap<int, StoryPageList>, StoryContentRequest>(
      _storyContentRequested),
  TypedReducer<BuiltMap<int, StoryPageList>, StoryContentSuccess>(
      _storyContentSucceeded),
  TypedReducer<BuiltMap<int, StoryPageList>, StoryInfoRequest>(
      _storyInfoRequested),
  TypedReducer<BuiltMap<int, StoryPageList>, StoryInfoSuccess>(
      _storyInfoSucceeded),
  TypedReducer<BuiltMap<int, StoryPageList>, StoryContentFailure>(
      _storyContentFailed),
  TypedReducer<BuiltMap<int, StoryPageList>, StoryInfoFailure>(
      _storyInfoFailed),
]);

BuiltMap<int, StoryPageList> _storyInfoRequested(
    BuiltMap<int, StoryPageList> storyRepo, StoryInfoRequest action) {
  var newRepo = storyRepo;

  if (action.story != null) {
    int threadId = action.story;
    newRepo = _buildStoryPages(newRepo, threadId, forceNew: true).rebuild((b) =>
        b.updateValue(threadId, (v) => v.rebuild((b) => b..loading = true)));
  }
  return newRepo;
}

BuiltMap<int, StoryPageList> _storyInfoSucceeded(
    BuiltMap<int, StoryPageList> storyRepo, StoryInfoSuccess action) {
  var newRepo = storyRepo;
  final result = action.result;

  if (result is StoryInfoResult) {
    int threadId = result.tid;

    newRepo = newRepo.rebuild((b) => b
      ..updateValue(
          threadId,
          (v) => v.rebuild((b) => b
            ..loading = false
            ..lastError = null
            ..storyInfo.replace(result))));
  }
  return newRepo;
}

BuiltMap<int, StoryPageList> _storyInfoFailed(
    BuiltMap<int, StoryPageList> storyRepo, StoryInfoFailure action) {
  int threadId;
  final request = action.request as StoryInfoRequest;
  if (request != null) {
    threadId = request.story;
  }
  return _storyRequestFailed(storyRepo, threadId, action);
}

BuiltMap<int, StoryPageList> _storyContentFailed(
    BuiltMap<int, StoryPageList> storyRepo, StoryContentFailure action) {
  int threadId;
  final request = action.request as StoryContentRequest;
  if (request != null) {
    threadId = request.story;
  }
  return _storyRequestFailed(storyRepo, threadId, action);
}

BuiltMap<int, StoryPageList> _storyRequestFailed(
    BuiltMap<int, StoryPageList> storyRepo, int threadId, APIFailure action) {
  var newRepo = storyRepo;
  if (threadId != null) {
    newRepo = newRepo.rebuild((b) => b
      ..updateValue(
          threadId,
          (v) => v.rebuild((b) => b
            ..loading = false
            ..lastError = action.error)));
  }
  return newRepo;
}

BuiltMap<int, StoryPageList> _buildStoryPages(
    BuiltMap<int, StoryPageList> newRepo, int threadId,
    {bool forceNew: false}) {
  StoryPageList storyContents = newRepo[threadId];
  if (forceNew || storyContents == null) {
    newRepo = newRepo
        .rebuild((b) => b..addEntries([MapEntry(threadId, StoryPageList())]));
    storyContents = newRepo[threadId];
  }
  return newRepo;
}

BuiltMap<int, StoryPageList> _storyContentRequested(
    BuiltMap<int, StoryPageList> storyRepo, StoryContentRequest action) {
  var newRepo = storyRepo;

  if (action.story != null) {
    int threadId = action.story;
    newRepo = _buildStoryPages(newRepo, threadId);

    StoryPageList storyContents = newRepo[threadId];
    StoryPage page = StoryPage();
    if (storyContents.pages[action.page] == null) {
      newRepo = newRepo.rebuild((b) => b.updateValue(
          threadId,
          (v) => v.rebuild((b) => b
            ..loading = true
            ..pages.addEntries([MapEntry(action.page, page)]))));
    }
  }
  return newRepo;
}

BuiltMap<int, StoryPageList> _storyContentSucceeded(
    BuiltMap<int, StoryPageList> storyRepo, StoryContentSuccess action) {
  var newRepo = storyRepo;
  final result = action.result;
  var id = parseLKTypeId(result.model);

  if (id != null) {
    int threadId = int.parse(id);
    StoryPage page =
        StoryPage().rebuild((b) => b..comments.replace(result.comments));
    var updater = (b) => b
      ..loading = false
      ..lastError = null
      ..pages.updateValue(result.page, (v) => page);
    newRepo = newRepo.rebuild(
      (b) => b
        ..updateValue(
          threadId,
          (v) => v.rebuild(updater),
          ifAbsent: () => StoryPageList().rebuild(updater),
        ),
    );
  }
  return newRepo;
}

final homeListReducer = combineReducers<StoryFetchList>([
  TypedReducer<StoryFetchList, HomeListRequest>(_homeListLoading),
  TypedReducer<StoryFetchList, HomeListFailure>(_homeListFailed),
  TypedReducer<StoryFetchList, HomeListCheckNewFailure>(_homeListFailed),
  TypedReducer<StoryFetchList, HomeListNewSuccess>(
      _homeListSucceeded(FetchListRequestType.New)),
  TypedReducer<StoryFetchList, HomeListRefreshSuccess>(
      _homeListSucceeded(FetchListRequestType.Refresh)),
  TypedReducer<StoryFetchList, HomeListLoadMoreSuccess>(
      _homeListSucceeded(FetchListRequestType.LoadMore)),
  TypedReducer<StoryFetchList, HomeListCheckNewSuccess>(
      _homeListNewCountChecked),
]);

StoryFetchList _homeListNewCountChecked(
    StoryFetchList list, HomeListCheckNewSuccess action) {
  var result = action.result;

  return fetchListNewCountChecked(list, result);
}

StoryFetchList _homeListLoading(StoryFetchList list, HomeListRequest action) {
  return fetchListLoading(list);
}

StoryFetchList _homeListFailed(StoryFetchList list, APIFailure action) {
  return fetchListFailed(list, action.error);
}

_homeListSucceeded(FetchListRequestType type) =>
    (StoryFetchList list, HomeListSuccess action) =>
        fetchListSucceeded(type, list, action.list);
