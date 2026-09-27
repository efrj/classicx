<%
'=======================================================================================================================
' ClassicX Tweet / Post Model
'=======================================================================================================================

Class TweetModel_Class


    Public Id
    Public UserId
    Public Content
    Public ImageUrl
    Public ParentId
    Public RepostId
    Public LikesCount
    Public RetweetsCount
    Public RepliesCount
    Public ViewsCount
    Public CreatedAt

    ' Author info
    Public UserName
    Public UserHandle
    Public UserAvatarUrl
    Public UserIsVerified

    ' Status flags for current user
    Public IsLiked
    Public IsRetweeted
    Public IsBookmarked
    Public TimeAgoFormatted

    ' Repost header info if this is a repost
    Public RepostUserName
    Public RepostUserHandle
End Class

%>
