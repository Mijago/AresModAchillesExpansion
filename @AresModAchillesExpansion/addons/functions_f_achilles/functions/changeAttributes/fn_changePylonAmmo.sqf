////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	AUTHOR: Kex, CoxLedere, CreepPork_LV
//	DATE: 07/10/2017 (DD/MM/YYYY)
//	VERSION: 3.0
//  DESCRIPTION: opens the "ammo" dialog for vehicles.
//
//	ARGUMENTS:
//	_this select 0		_vehicle (optional)
//
//	RETURNS:
//	nothing (procedure)
//
//	Example:
//	[_vehicle] call Achilles_fnc_changePylonAmmo;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

params ["_plane"];
private _planeType = typeOf _plane;
if (!isClass (configFile >> "cfgVehicles" >> _planeType >> "Components" >> "TransportPylonsComponent")) exitWith {[localize "STR_AMAE_NO_DYNAMIC_LOADOUT"] call Achilles_fnc_ShowZeusErrorMessage; nil};

private _hasGunner = not isNull gunner _plane;

private _allCurrentPylonMagazines = getPylonMagazines _plane;
private _pylon_cfgs = (configFile >> "cfgVehicles" >> _planeType >> "Components" >> "TransportPylonsComponent" >> "pylons") call BIS_fnc_returnChildren;
private _entries = [];
private _addWeaponsTo = [];
if (_hasGunner) then 
{
	_addWeaponsTo = if(_plane getVariable ["Achilles_var_changePylonAmmo_Assigned", [0]] isEqualTo []) then {0} else {1};
	_entries pushBack [localize "STR_AMAE_ASSIGN_WEAPONS", [localize "STR_AMAE_DRIVER", localize "STR_AMAE_GUNNER"], _addWeaponsTo, true];
};
{
	private _pylon_cfg = _x;
	private _pylonIndex = _forEachIndex + 1;
	private _magazineNames = ["Empty"];
	private _defaultIndex = 0;
	{
		private _mag_cfg = (configFile >> "cfgMagazines" >> _x);
		_magazineNames pushBack format ["%1 (%2)", getText (_mag_cfg >> "displayName"), getText (_mag_cfg >> "DisplayNameShort")];
		if (configName _mag_cfg == _allCurrentPylonMagazines select (_pylonIndex - 1)) then {_defaultIndex = _forEachIndex + 1};
	} forEach (_plane getCompatiblePylonMagazines _pylonIndex);

	_entries pushBack [configName _pylon_cfg, _magazineNames, _defaultIndex, true];
} forEach _pylon_cfgs;

private _dialogResult = [localize "STR_AMAE_LOADOUT", _entries] call Ares_fnc_ShowChooseDialog;

if (_dialogResult isEqualTo []) exitWith {};
private _curatorSelected = ["vehicle"] call Achilles_fnc_getCuratorSelected;
_curatorSelected = _curatorSelected select {_x isKindOf _planeType};

if (_hasGunner) then
{
	_addWeaponsTo = [[], [0]] select (_dialogResult select 0 == 1);
	_plane setVariable ["Achilles_var_changePylonAmmo_Assigned", _addWeaponsTo, true];
};

if (_hasGunner) then {_dialogResult deleteAt 0};

{
	private _plane = _x;
	{_plane removeWeaponTurret [getText (configFile >> "CfgMagazines" >> _x >> "pylonWeapon"),[-1]]} forEach (_plane getCompatiblePylonMagazines _forEachIndex + 1);
	{_plane removeWeaponTurret [getText (configFile >> "CfgMagazines" >> _x >> "pylonWeapon"),[0]]} forEach (_plane getCompatiblePylonMagazines _forEachIndex + 1);
	{
		private _magIndex = _x;
		private _pylonIndex = _forEachIndex + 1;
		private _magClassName = if (_x > 0) then {(_plane getCompatiblePylonMagazines _pylonIndex) select (_magIndex - 1)} else {""};
		if (local _plane) then
		{
			_plane setPylonLoadOut [_pylonIndex, _magClassName, false, _addWeaponsTo];
		}
		else
		{
			[_plane, [_pylonIndex, _magClassName, false, _addWeaponsTo]] remoteExecCall ["setPylonLoadOut", _plane];
		};
	} forEach _dialogResult;
} forEach _curatorSelected;
