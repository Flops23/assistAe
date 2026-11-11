package com.flops23.assistae

enum class Screen { HOME, PROFILE, CREATE, JOIN, PUBLIC_ROOMS, ROOM, SETTINGS, FRIENDS }

data class AppState(
    val screen: Screen = Screen.PROFILE,
    val busy: Boolean = true,
    val error: String? = null,
    val nickname: String = "",
    val publicRooms: List<PublicRoom> = emptyList(),
    val room: RoomState? = null,
    val messages: List<ChatMessage> = emptyList(),
    val friends: List<Friend> = emptyList(),
    val requests: List<FriendRequest> = emptyList(),
    val invites: List<Invite> = emptyList(),
    val friendCode: String = "",
    val notifyInvites: Boolean = true,
    val notifyFriendships: Boolean = true,
    val messagePosition: String = "bottom",
    val messageSize: String = "small",
    val messageSpeed: String = "normal",
    val betaId: String? = null,
)

data class PublicRoom(val id: String, val name: String, val connected: Int)
data class RoomState(
    val id: String, val name: String, val code: String?, val connected: Int,
    val canControl: Boolean, val isAdmin: Boolean, val reconnecting: Boolean,
    val playback: PlaybackState, val queue: List<QueueItem>, val participants: List<Participant>,
)
data class PlaybackState(val status: String, val durationMs: Long?, val positionMs: Long, val terminationMode: String?, val title: String? = null)
data class QueueItem(val id: String, val title: String)
data class Participant(val id: String, val nickname: String, val isAdmin: Boolean, val canControl: Boolean, val isSelf: Boolean, val connected: Boolean = true)
data class ChatMessage(val id: String, val nickname: String, val body: String)
data class Friend(val id: String, val nickname: String)
data class FriendRequest(val id: String, val nickname: String, val incoming: Boolean)
data class Invite(val id: String, val nickname: String, val roomName: String)

sealed interface AppAction {
    data class Navigate(val screen: Screen) : AppAction
    data object DismissError : AppAction
    data object Retry : AppAction
    data class EnsureProfile(val nickname: String) : AppAction
    data class CreateRoom(val name: String, val isPublic: Boolean) : AppAction
    data class JoinCode(val code: String) : AppAction
    data class JoinPublic(val id: String) : AppAction
    data class JoinInvite(val id: String) : AppAction
    data class SearchRooms(val query: String) : AppAction
    data object LoadRoomCode : AppAction
    data class SendMessage(val body: String) : AppAction
    data class LeaveRoom(val successorId: String? = null) : AppAction
    data object CloseRoom : AppAction
    data object PlayPause : AppAction
    data class SeekBy(val deltaMs: Long) : AppAction
    data object Advance : AppAction
    data class AddVideo(val url: String, val now: Boolean) : AppAction
    data class ReorderQueue(val ids: List<String>) : AppAction
    data class RemoveQueue(val id: String) : AppAction
    data class ChangeNickname(val nickname: String) : AppAction
    data class SetNotification(val kind: String, val enabled: Boolean) : AppAction
    data class SaveMessagePreferences(val position: String, val size: String, val speed: String) : AppAction
    data object RefreshFriends : AppAction
    data class RequestFriend(val code: String) : AppAction
    data class AnswerFriend(val id: String, val accept: Boolean) : AppAction
    data class CancelFriend(val id: String) : AppAction
    data class RemoveFriend(val id: String) : AppAction
    data class InviteFriend(val id: String) : AppAction
    data class SetControl(val id: String, val enabled: Boolean) : AppAction
    data class TransferAdmin(val id: String) : AppAction
    data class KickMember(val id: String, val ban: Boolean) : AppAction
}
