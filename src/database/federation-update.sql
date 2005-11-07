use [federation]
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[GetCharSquads]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[GetCharSquads]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadAcceptJoinRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadAcceptJoinRequest]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadBootMember]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadBootMember]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadCancelJoinRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadCancelJoinRequest]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadCreate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadCreate]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadDemoteToMember]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadDemoteToMember]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadDetails]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadDetailsPlayers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadDetailsPlayers]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadEdit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadEdit]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadGetDudeXSquads]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadGetDudeXSquads]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadMakeJoinRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadMakeJoinRequest]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadPromoteToASL]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadPromoteToASL]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadQuit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadQuit]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadRejectJoinRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadRejectJoinRequest]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SquadTransferControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SquadTransferControl]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SyncZoneSquads]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[SyncZoneSquads]
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


CREATE Procedure GetCharSquads
(
	@characterID int
)
As
set nocount on 

create table #playerTeams
(
	vc_team_name varchar(30),
	i_status int,
	i_team_id int,
	i_secondary_status int
)	

insert into #playerTeams
	exec profile.dbo.p_get_player_teams_aleg @characterID

select rtrim(s.SquadName), i_status, i_team_id, i_secondary_status 
	from #playerTeams p, Squads s where s.squadID = p.i_team_id
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadAcceptJoinRequest

	(
		@MemberID int,
		@SquadID int
	)

As
set nocount on 

declare @ErrorMsg as varchar(128)
declare @ErrorCode as int

exec profile.dbo.p_grant_petitions_aleg @SquadID, @MemberID, @ErrorCode output, @ErrorMsg output

if @ErrorCode is null select 0
else select @ErrorCode

return






















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadBootMember

	(
		@MemberID int,
		@SquadID int
	)

As
set nocount on 

declare @ErrorMsg as varchar(128)
declare @ErrorCode as int
declare @status as int
declare @newownerID as int -- modified KGJV

exec profile.dbo.p_withdraw_team_aleg @SquadID, @MemberID, @status output, @newownerID output, @ErrorCode output, @ErrorMsg output

if @status = -1 delete from squads where squadid = @squadid
else if @newownerID is not null  -- modified KGJV
	begin
		declare @newowner as varchar(30)
		select @newowner = CharacterName from CharacterInfo where CharacterID = @newownerID
		exec SquadAddNewLeaderToLog @SquadID, @newowner
	end

if (@status is null) select @ErrorCode, 0
else select @ErrorCode, @status -- status is -1 if team was destroyed because last person left

return






















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadCancelJoinRequest

	(
		@MemberID int,
		@SquadID int
	)

As
set nocount on 

declare @ErrorMsg as varchar(128)
declare @ErrorCode as int
declare @status as int
declare @newowner as varchar(30)

exec profile.dbo.p_withdraw_team_aleg @SquadID, @MemberID, @status output, @newowner output, @ErrorCode output, @ErrorMsg output

-- this shouldn't ever happen, but let's be safe
if @status = -1 delete from squads where squadid = @squadid
else if @newowner is not null exec SquadAddNewLeaderToLog @SquadID, @newowner

if @ErrorCode is null select 0
else select @ErrorCode

return























GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadCreate

	(
		@SquadName			varchar(30),
		@Description		varchar(510),
		@URL				varchar(255),
		@OwnerID			int,
		@civID				smallint
--		@SquadID			int		     OUTPUT,
--		@ErrorCode			int		 	 OUTPUT,
--		@ErrorMsg			varchar(128) OUTPUT
	)

As

set nocount on

-- trim these down so we don't waste space
select @squadname = rtrim(@squadname)
select @Description = rtrim(@Description)
select @URL = rtrim(@URL) 

declare	@SquadID	int		     
declare	@ErrorCode	int		 	 
declare	@ErrorMsg	varchar(128)

exec profile.dbo.p_create_team_profile_aleg @SquadName, @Description, @URL, @OwnerID, @SquadID output, @ErrorCode output, @ErrorMsg output
/*
-- This is a workaround until the p_create_team_profile_aleg returns a squadid properly
create table #temp2
(
  vc_team_name varchar(30),
  i_status int,
  i_team_id int,
  i_status2 int
)

insert #temp2
  exec profile.profile.dbo.p_get_player_teams_aleg @OwnerID

select @squadID = i_team_id from #temp2 where vc_team_name = @SquadName
*/
	if @ErrorCode = 0
	begin
		delete from squads where SquadID = @SquadID or squadname = @squadname -- remove existing, if any
		insert Squads 
		-- TODO make more robust using pairing of Columns and Values 
		-- select @SquadID, @SquadName, 0, 0, 0, (select CharacterName from CharacterInfo where CharacterID = @OwnerID), @civID
		select @SquadID, @SquadName, 0, 0, 0, '', @civID, 0
		
		-- add new leader to ownership log 
    	declare @charname name
		select @charname = charactername from characterinfo where characterid = @ownerid
		if @charname is not null exec SquadAddNewLeaderToLog @SquadID, @charname
	end

select @SquadID, @ErrorCode, @ErrorMsg


















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadDemoteToMember

	(
		@MemberID int,
		@SquadID int
	)

As
set nocount on 

declare @ErrorMsg as varchar(128)
declare @ErrorCode as int

exec profile.dbo.p_edit_team_member_status2_aleg @SquadID, @MemberID, 0, @ErrorCode output, @ErrorMsg output

select @ErrorCode

return






















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadDetails

	(
		@SquadID int
	)

As

set nocount on

-- todo include rank and civid

create table #temp
(
	vc_team_id			 varchar(30),
	vc_member_id		 varchar(30),
	vc_description		 varchar(510),
	vc_favorite_game1	 varchar(4), 
	vc_favorite_game2	 varchar(4),  
	vc_favorite_game3	 varchar(4),  
	vc_favorite_game4	 varchar(4),  
	vc_favorite_game5	 varchar(4),  
	vc_favorite_link	 varchar(255),
	b_closed			 bit,
	b_award				 bit,
	i_team_id			 int,  
	vc_edit_restrictions varchar(8),
	dt_created		     datetime
)

insert #temp
  exec profile.dbo.p_get_team_profile_aleg @SquadID

select #temp.*, s.civid/*, s.rank*/ from #temp, Squads s where s.SquadID = @SquadID 

declare @c_rows as int
select @c_rows = count(*) from #temp
if @c_rows = 0 delete from squads where squadid = @squadID

return 





















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


CREATE Procedure SquadDetailsPlayers

	(
		@SquadID int
	)

As

set nocount on

CREATE TABLE #members (
	[i_account_id] [int] NOT NULL ,
--	[vc_member_id] [varchar] (30) NOT NULL , -- removed as our 'profile' db doesnt store char names
	[i_status] [int] NOT NULL ,
	[i_secondary_status] [int] NULL ,
	[dt_granted] [datetime] NOT NULL 
)

insert into #members
	exec profile.dbo.p_get_team_members_aleg @SquadID

select m.i_account_id, c.CharacterName, m.i_status, m.i_secondary_status, m.dt_granted, c.rank
	from #members m, charstats c 
	where c.characterid=m.i_account_id and c.civid is null

drop table #members
return 


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


CREATE Procedure SquadEdit


	(
		@SquadID			int,
		@Description		varchar(510),
		@URL				varchar(255),
		@civID				smallint
	)

As

set nocount on

select @Description = rtrim(@Description)
select @URL = rtrim(@URL) 

declare	@ErrorCode	int		 	 
declare	@ErrorMsg	varchar(128)

exec profile.dbo.p_edit_team_profile_aleg @SquadID, @Description, @URL, @ErrorCode output, @ErrorMsg output

	if @ErrorCode = 0
	begin
		-- now update federation database
		update squads
			set civid = @civid 
			where squadid = @squadid
	end

select @ErrorCode, @ErrorMsg






















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadGetDudeXSquads
(
	@characterID int
)
As
set nocount on

create table #playerTeamsX
(
	vc_team_name varchar(30),
	i_status int,
	i_team_id int,
	i_secondary_status int
)

insert #playerTeamsX
	exec profile.dbo.p_get_player_teams_aleg @characterID

select s.* from Squads s, #playerTeamsX p where s.squadID=p.i_team_ID

return 





















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadMakeJoinRequest

	(
		@MemberID int,
		@SquadID int
	)

As
set nocount on 

declare @ErrorMsg as varchar(128)
declare @ErrorCode as int

exec profile.dbo.p_petition_team_aleg @SquadID, @MemberID, @ErrorCode output, @ErrorMsg output

if @ErrorCode is null select 0
else select @ErrorCode

return






















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadPromoteToASL

	(
		@MemberID int,
		@SquadID int
	)

As
set nocount on 

declare @ErrorMsg as varchar(128)
declare @ErrorCode as int

exec profile.dbo.p_edit_team_member_status2_aleg @SquadID, @MemberID, 1, @ErrorCode output, @ErrorMsg output

select @ErrorCode

return






















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadQuit

	(
		@MemberID int,
		@SquadID int
	)

As
set nocount on 

declare @ErrorMsg as varchar(128)
declare @ErrorCode as int
declare @status as int
declare @newownerid as int

exec profile.dbo.p_withdraw_team_aleg @SquadID, @MemberID, @status output, @newownerid output, @ErrorCode output, @ErrorMsg output

if @status = -1 delete from squads where squadid = @squadid
else if @newownerid is not null
	begin
		declare @charname name
		select @charname = charactername from characterinfo where characterid = @newownerid
		if @charname is not null exec SquadAddNewLeaderToLog @SquadID, @charname
	end

if (@status is null) select @ErrorCode, 0
else select @ErrorCode, @status -- status is -1 if team was destroyed because last person left

return






















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadRejectJoinRequest

	(
		@MemberID int,
		@SquadID int
	)

As
set nocount on 

declare @ErrorMsg as varchar(128)
declare @ErrorCode as int


exec profile.dbo.p_deny_petitions_aleg @SquadID, @MemberID, @ErrorCode output, @ErrorMsg output

if @ErrorCode is null select 0
else select @ErrorCode

return






















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SquadTransferControl

	(
		@NewOwnerID int,
		@SquadID int
	)

As
set nocount on 

declare @ErrorMsg as varchar(128)
declare @ErrorCode as int

exec profile.dbo.p_change_team_ownership_aleg @SquadID, @NewOwnerID, @ErrorCode output, @ErrorMsg output

-- add new leader to ownership log 
if @errorcode = 0
begin
	declare @charname name
	select @charname = charactername from characterinfo where characterid = @newownerid
	if @charname is not null exec SquadAddNewLeaderToLog @SquadID, @charname
end 

select @ErrorCode 

return






















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE Procedure SyncZoneSquads
As
set nocount on
Declare cur Cursor Local For
    Select characterID From CharacterInfo
Open cur

create table #playerTeams
(
	vc_team_name varchar(30),
	i_status int,
	i_team_id int,
	i_secondary_status int
)	

Declare curTeam Cursor Local For
    select i_team_id, vc_team_name from #playerTeams

declare @characterID int
declare @vc_team_name varchar(30)
declare @i_status int
declare @i_team_id int
declare @i_secondary_status int

Fetch Next From cur Into @characterID

While @@FETCH_STATUS = 0
Begin

	insert into #playerTeams
		exec profile.dbo.p_get_player_teams_aleg @characterID
	
	Open curTeam

	declare @teamID int
	declare @squadName varchar(30)
	Fetch Next From curTeam Into @i_team_id, @vc_team_name
	
	While @@FETCH_STATUS = 0
	Begin
		if not exists (select * from Squads where SquadID=@i_team_id)
				insert into squads (squadid, squadname) 
					values (@i_team_id, @vc_team_name) 
			Fetch Next From curTeam Into @i_team_id, @vc_team_name
	End
	
	Close curTeam
	delete from #playerTeams
	Fetch Next From cur Into @characterID
End

Close cur
return 


















GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

