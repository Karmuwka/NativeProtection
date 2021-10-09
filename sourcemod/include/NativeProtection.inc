// Возвращает состояние игрока в игре - true защищен, false нет
native int SP_GetClientProtectionState(int client);
// Устанавливает/убирает защиту с игрока
native void SP_SetClientProtectionState(int client, bool state, float time = 0.0);