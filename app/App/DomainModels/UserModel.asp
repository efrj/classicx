<%
'=======================================================================================================================
' ClassicX User Model
'=======================================================================================================================

Class UserModel_Class


    Public Id
    Public Username
    Public Handle
    Public Email
    Public PasswordHash
    Public Name
    Public Bio
    Public Location
    Public Website
    Public AvatarUrl
    Public BannerUrl
    Public IsVerified
    Public CreatedAt

    ' Computed / Aggregate fields
    Public FollowersCount
    Public FollowingCount
    Public TweetsCount
    Public IsFollowedByCurrent
End Class

%>
