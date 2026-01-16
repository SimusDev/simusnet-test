@tool
extends Node
class_name SimusNetVarsProccessorSend

@export var _vars: SimusNetVars
@export_multiline var source: String = ""
@export_tool_button("Generate Code") var _tb_generate_code = _generate_code

func _generate_code() -> void:
	var source: String = source
	var generated: String = ""
	for id in SimusNetChannels.MAX:
		var str_id: String = str(id)
		generated += source % [str_id, str_id, str_id, str_id] + "\n\n"
	
	DisplayServer.clipboard_set(generated)

func _recieve_send_packet_local(packet: Variant, from_peer: int) -> void:
	_vars._recieve_send_packet_local(packet, from_peer)

@rpc("any_peer", "call_remote", "reliable", SimusNetChannels.BUILTIN.VARS_SEND_RELIABLE)
func _default_recieve_send(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", SimusNetChannels.BUILTIN.VARS_SEND)
func _default_recieve_send_unreliable(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

#//////////////////////////////////////////////////////////////////////////////////


@rpc("any_peer", "call_remote", "reliable", 0)
func _r_s_p_l_r0(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 0)
func _r_s_p_l_u0(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 1)
func _r_s_p_l_r1(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 1)
func _r_s_p_l_u1(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 2)
func _r_s_p_l_r2(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 2)
func _r_s_p_l_u2(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 3)
func _r_s_p_l_r3(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 3)
func _r_s_p_l_u3(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 4)
func _r_s_p_l_r4(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 4)
func _r_s_p_l_u4(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 5)
func _r_s_p_l_r5(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 5)
func _r_s_p_l_u5(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 6)
func _r_s_p_l_r6(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 6)
func _r_s_p_l_u6(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 7)
func _r_s_p_l_r7(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 7)
func _r_s_p_l_u7(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 8)
func _r_s_p_l_r8(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 8)
func _r_s_p_l_u8(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 9)
func _r_s_p_l_r9(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 9)
func _r_s_p_l_u9(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 10)
func _r_s_p_l_r10(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 10)
func _r_s_p_l_u10(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 11)
func _r_s_p_l_r11(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 11)
func _r_s_p_l_u11(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 12)
func _r_s_p_l_r12(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 12)
func _r_s_p_l_u12(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 13)
func _r_s_p_l_r13(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 13)
func _r_s_p_l_u13(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 14)
func _r_s_p_l_r14(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 14)
func _r_s_p_l_u14(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 15)
func _r_s_p_l_r15(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 15)
func _r_s_p_l_u15(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 16)
func _r_s_p_l_r16(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 16)
func _r_s_p_l_u16(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 17)
func _r_s_p_l_r17(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 17)
func _r_s_p_l_u17(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 18)
func _r_s_p_l_r18(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 18)
func _r_s_p_l_u18(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 19)
func _r_s_p_l_r19(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 19)
func _r_s_p_l_u19(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 20)
func _r_s_p_l_r20(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 20)
func _r_s_p_l_u20(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 21)
func _r_s_p_l_r21(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 21)
func _r_s_p_l_u21(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 22)
func _r_s_p_l_r22(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 22)
func _r_s_p_l_u22(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 23)
func _r_s_p_l_r23(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 23)
func _r_s_p_l_u23(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 24)
func _r_s_p_l_r24(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 24)
func _r_s_p_l_u24(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 25)
func _r_s_p_l_r25(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 25)
func _r_s_p_l_u25(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 26)
func _r_s_p_l_r26(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 26)
func _r_s_p_l_u26(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 27)
func _r_s_p_l_r27(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 27)
func _r_s_p_l_u27(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 28)
func _r_s_p_l_r28(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 28)
func _r_s_p_l_u28(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 29)
func _r_s_p_l_r29(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 29)
func _r_s_p_l_u29(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 30)
func _r_s_p_l_r30(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 30)
func _r_s_p_l_u30(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 31)
func _r_s_p_l_r31(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 31)
func _r_s_p_l_u31(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 32)
func _r_s_p_l_r32(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 32)
func _r_s_p_l_u32(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 33)
func _r_s_p_l_r33(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 33)
func _r_s_p_l_u33(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 34)
func _r_s_p_l_r34(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 34)
func _r_s_p_l_u34(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 35)
func _r_s_p_l_r35(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 35)
func _r_s_p_l_u35(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 36)
func _r_s_p_l_r36(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 36)
func _r_s_p_l_u36(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 37)
func _r_s_p_l_r37(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 37)
func _r_s_p_l_u37(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 38)
func _r_s_p_l_r38(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 38)
func _r_s_p_l_u38(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 39)
func _r_s_p_l_r39(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 39)
func _r_s_p_l_u39(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 40)
func _r_s_p_l_r40(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 40)
func _r_s_p_l_u40(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 41)
func _r_s_p_l_r41(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 41)
func _r_s_p_l_u41(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 42)
func _r_s_p_l_r42(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 42)
func _r_s_p_l_u42(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 43)
func _r_s_p_l_r43(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 43)
func _r_s_p_l_u43(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 44)
func _r_s_p_l_r44(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 44)
func _r_s_p_l_u44(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 45)
func _r_s_p_l_r45(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 45)
func _r_s_p_l_u45(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 46)
func _r_s_p_l_r46(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 46)
func _r_s_p_l_u46(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 47)
func _r_s_p_l_r47(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 47)
func _r_s_p_l_u47(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 48)
func _r_s_p_l_r48(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 48)
func _r_s_p_l_u48(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 49)
func _r_s_p_l_r49(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 49)
func _r_s_p_l_u49(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 50)
func _r_s_p_l_r50(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 50)
func _r_s_p_l_u50(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 51)
func _r_s_p_l_r51(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 51)
func _r_s_p_l_u51(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 52)
func _r_s_p_l_r52(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 52)
func _r_s_p_l_u52(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 53)
func _r_s_p_l_r53(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 53)
func _r_s_p_l_u53(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 54)
func _r_s_p_l_r54(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 54)
func _r_s_p_l_u54(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 55)
func _r_s_p_l_r55(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 55)
func _r_s_p_l_u55(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 56)
func _r_s_p_l_r56(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 56)
func _r_s_p_l_u56(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 57)
func _r_s_p_l_r57(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 57)
func _r_s_p_l_u57(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 58)
func _r_s_p_l_r58(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 58)
func _r_s_p_l_u58(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 59)
func _r_s_p_l_r59(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 59)
func _r_s_p_l_u59(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 60)
func _r_s_p_l_r60(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 60)
func _r_s_p_l_u60(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 61)
func _r_s_p_l_r61(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 61)
func _r_s_p_l_u61(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 62)
func _r_s_p_l_r62(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 62)
func _r_s_p_l_u62(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 63)
func _r_s_p_l_r63(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 63)
func _r_s_p_l_u63(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 64)
func _r_s_p_l_r64(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 64)
func _r_s_p_l_u64(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 65)
func _r_s_p_l_r65(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 65)
func _r_s_p_l_u65(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 66)
func _r_s_p_l_r66(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 66)
func _r_s_p_l_u66(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 67)
func _r_s_p_l_r67(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 67)
func _r_s_p_l_u67(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 68)
func _r_s_p_l_r68(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 68)
func _r_s_p_l_u68(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 69)
func _r_s_p_l_r69(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 69)
func _r_s_p_l_u69(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 70)
func _r_s_p_l_r70(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 70)
func _r_s_p_l_u70(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable", 71)
func _r_s_p_l_r71(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "unreliable", 71)
func _r_s_p_l_u71(packet: Variant) -> void:
	_recieve_send_packet_local(packet, multiplayer.get_remote_sender_id())
