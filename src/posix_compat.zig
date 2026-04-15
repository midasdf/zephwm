// Zig 0.16 compatibility shim.
//
// In Zig 0.16, many POSIX wrappers were removed from std.posix in favor of
// the new std.Io abstraction. Threading `Io` through the entire codebase is
// a much larger refactor than is feasible here; since zephwm always links
// libc anyway, this shim wraps the corresponding `std.c.*` libc externs and
// mirrors the previous std.posix signatures closely enough for callers to
// use unchanged.
//
// All functions return Zig errors using std.c.errno() to inspect errno.

const std = @import("std");
const c = std.c;
const posix = std.posix;

pub const fd_t = posix.fd_t;
pub const socklen_t = c.socklen_t;
pub const sockaddr = posix.sockaddr;
pub const mode_t = c.mode_t;

pub const AT = posix.AT;
pub const AF = posix.AF;
pub const SOCK = posix.SOCK;

pub const SocketError = error{
    PermissionDenied,
    AddressFamilyNotSupported,
    ProtocolFamilyNotAvailable,
    ProcessFdQuotaExceeded,
    SystemFdQuotaExceeded,
    SystemResources,
    ProtocolNotSupported,
    SocketTypeNotSupported,
    Unexpected,
};

pub fn socket(domain: u32, sock_type: u32, protocol: u32) SocketError!fd_t {
    const rc = c.socket(domain, sock_type, protocol);
    if (rc >= 0) return rc;
    return switch (c.errno(rc)) {
        .ACCES => error.PermissionDenied,
        .AFNOSUPPORT => error.AddressFamilyNotSupported,
        .INVAL => error.ProtocolFamilyNotAvailable,
        .MFILE => error.ProcessFdQuotaExceeded,
        .NFILE => error.SystemFdQuotaExceeded,
        .NOBUFS, .NOMEM => error.SystemResources,
        .PROTONOSUPPORT => error.ProtocolNotSupported,
        .PROTOTYPE => error.SocketTypeNotSupported,
        else => error.Unexpected,
    };
}

pub fn close(fd: fd_t) void {
    _ = c.close(fd);
}

pub const BindError = error{
    AccessDenied,
    AddressInUse,
    AddressNotAvailable,
    AddressFamilyNotSupported,
    SymLinkLoop,
    NameTooLong,
    FileNotFound,
    SystemResources,
    NotDir,
    ReadOnlyFileSystem,
    AlreadyBound,
    NotASocket,
    Unexpected,
};

pub fn bind(fd: fd_t, addr: *const sockaddr, addrlen: socklen_t) BindError!void {
    const rc = c.bind(fd, addr, addrlen);
    if (rc == 0) return;
    return switch (c.errno(rc)) {
        .ACCES => error.AccessDenied,
        .ADDRINUSE => error.AddressInUse,
        .ADDRNOTAVAIL => error.AddressNotAvailable,
        .AFNOSUPPORT => error.AddressFamilyNotSupported,
        .LOOP => error.SymLinkLoop,
        .NAMETOOLONG => error.NameTooLong,
        .NOENT => error.FileNotFound,
        .NOMEM => error.SystemResources,
        .NOTDIR => error.NotDir,
        .ROFS => error.ReadOnlyFileSystem,
        .INVAL => error.AlreadyBound,
        .NOTSOCK => error.NotASocket,
        else => error.Unexpected,
    };
}

pub const ListenError = error{
    AddressInUse,
    FileDescriptorNotASocket,
    OperationNotSupported,
    SystemResources,
    Unexpected,
};

pub fn listen(fd: fd_t, backlog: u31) ListenError!void {
    const rc = c.listen(fd, backlog);
    if (rc == 0) return;
    return switch (c.errno(rc)) {
        .ADDRINUSE => error.AddressInUse,
        .BADF, .NOTSOCK => error.FileDescriptorNotASocket,
        .OPNOTSUPP => error.OperationNotSupported,
        .NOBUFS => error.SystemResources,
        else => error.Unexpected,
    };
}

pub const AcceptError = error{
    WouldBlock,
    ConnectionAborted,
    FileDescriptorNotASocket,
    ProcessFdQuotaExceeded,
    SystemFdQuotaExceeded,
    SystemResources,
    OperationNotSupported,
    ProtocolFailure,
    Unexpected,
};

pub fn accept(fd: fd_t, addr: ?*sockaddr, addrlen: ?*socklen_t, flags: u32) AcceptError!fd_t {
    const rc = c.accept4(fd, addr, addrlen, flags);
    if (rc >= 0) return rc;
    return switch (c.errno(rc)) {
        .AGAIN => error.WouldBlock,
        .CONNABORTED => error.ConnectionAborted,
        .BADF, .NOTSOCK, .OPNOTSUPP => error.FileDescriptorNotASocket,
        .MFILE => error.ProcessFdQuotaExceeded,
        .NFILE => error.SystemFdQuotaExceeded,
        .NOBUFS, .NOMEM => error.SystemResources,
        .PROTO => error.ProtocolFailure,
        else => error.Unexpected,
    };
}

pub const ConnectError = error{
    PermissionDenied,
    AddressInUse,
    AddressNotAvailable,
    AddressFamilyNotSupported,
    WouldBlock,
    ConnectionPending,
    FileDescriptorNotASocket,
    ConnectionRefused,
    ConnectionResetByPeer,
    NetworkUnreachable,
    ConnectionTimedOut,
    FileNotFound,
    Unexpected,
};

pub fn connect(fd: fd_t, addr: *const sockaddr, addrlen: socklen_t) ConnectError!void {
    const rc = c.connect(fd, addr, addrlen);
    if (rc == 0) return;
    return switch (c.errno(rc)) {
        .ACCES, .PERM => error.PermissionDenied,
        .ADDRINUSE => error.AddressInUse,
        .ADDRNOTAVAIL => error.AddressNotAvailable,
        .AFNOSUPPORT => error.AddressFamilyNotSupported,
        .AGAIN, .INPROGRESS => error.WouldBlock,
        .ALREADY => error.ConnectionPending,
        .BADF, .NOTSOCK => error.FileDescriptorNotASocket,
        .CONNREFUSED => error.ConnectionRefused,
        .CONNRESET => error.ConnectionResetByPeer,
        .NETUNREACH => error.NetworkUnreachable,
        .TIMEDOUT => error.ConnectionTimedOut,
        .NOENT => error.FileNotFound,
        else => error.Unexpected,
    };
}

pub const WriteError = error{
    DiskQuota,
    FileTooBig,
    InputOutput,
    NoSpaceLeft,
    AccessDenied,
    BrokenPipe,
    ConnectionResetByPeer,
    WouldBlock,
    Unexpected,
};

pub fn write(fd: fd_t, buf: []const u8) WriteError!usize {
    const rc = c.write(fd, buf.ptr, buf.len);
    if (rc >= 0) return @intCast(rc);
    return switch (c.errno(rc)) {
        .DQUOT => error.DiskQuota,
        .FBIG => error.FileTooBig,
        .IO => error.InputOutput,
        .NOSPC => error.NoSpaceLeft,
        .PERM => error.AccessDenied,
        .PIPE => error.BrokenPipe,
        .CONNRESET => error.ConnectionResetByPeer,
        .AGAIN => error.WouldBlock,
        else => error.Unexpected,
    };
}

pub const PipeError = error{
    SystemFdQuotaExceeded,
    ProcessFdQuotaExceeded,
    Unexpected,
};

pub fn pipe() PipeError![2]fd_t {
    var fds: [2]fd_t = undefined;
    const rc = c.pipe(&fds);
    if (rc == 0) return fds;
    return switch (c.errno(rc)) {
        .NFILE => error.SystemFdQuotaExceeded,
        .MFILE => error.ProcessFdQuotaExceeded,
        else => error.Unexpected,
    };
}

pub const MkdirError = error{
    AccessDenied,
    PathAlreadyExists,
    SymLinkLoop,
    LinkQuotaExceeded,
    NameTooLong,
    FileNotFound,
    SystemResources,
    NoSpaceLeft,
    NotDir,
    ReadOnlyFileSystem,
    BadPathName,
    Unexpected,
};

pub fn mkdirat(dirfd: fd_t, path: []const u8, mode: mode_t) MkdirError!void {
    var path_z: [std.posix.PATH_MAX:0]u8 = undefined;
    if (path.len >= path_z.len) return error.NameTooLong;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const rc = c.mkdirat(dirfd, &path_z, mode);
    if (rc == 0) return;
    return switch (c.errno(rc)) {
        .ACCES, .PERM => error.AccessDenied,
        .EXIST => error.PathAlreadyExists,
        .LOOP => error.SymLinkLoop,
        .MLINK => error.LinkQuotaExceeded,
        .NAMETOOLONG => error.NameTooLong,
        .NOENT => error.FileNotFound,
        .NOMEM => error.SystemResources,
        .NOSPC => error.NoSpaceLeft,
        .NOTDIR => error.NotDir,
        .ROFS => error.ReadOnlyFileSystem,
        else => error.Unexpected,
    };
}

pub fn unlinkat(dirfd: fd_t, path: []const u8, flags: u32) !void {
    var path_z: [std.posix.PATH_MAX:0]u8 = undefined;
    if (path.len >= path_z.len) return error.NameTooLong;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const rc = c.unlinkat(dirfd, &path_z, flags);
    if (rc == 0) return;
    return switch (c.errno(rc)) {
        .ACCES, .PERM => error.AccessDenied,
        .BUSY => error.FileBusy,
        .NOENT => error.FileNotFound,
        .NOTDIR => error.NotDir,
        .ROFS => error.ReadOnlyFileSystem,
        else => error.Unexpected,
    };
}

pub fn dup(fd: fd_t) !fd_t {
    const rc = std.c.dup(fd);
    if (rc >= 0) return rc;
    return switch (c.errno(rc)) {
        .MFILE => error.ProcessFdQuotaExceeded,
        else => error.Unexpected,
    };
}

pub const FcntlError = error{
    PermissionDenied,
    FileBusy,
    ProcessFdQuotaExceeded,
    Locked,
    Unexpected,
};

pub fn fcntl(fd: fd_t, cmd: i32, arg: usize) FcntlError!usize {
    const rc = c.fcntl(fd, cmd, arg);
    if (rc >= 0) return @intCast(rc);
    return switch (c.errno(rc)) {
        .ACCES => error.PermissionDenied,
        .BUSY => error.FileBusy,
        .MFILE => error.ProcessFdQuotaExceeded,
        .AGAIN, .NOLCK => error.Locked,
        else => error.Unexpected,
    };
}

pub const ForkError = error{
    SystemResources,
    ProcessFdQuotaExceeded,
    Unexpected,
};

pub fn fork() ForkError!std.posix.pid_t {
    const rc = c.fork();
    if (rc >= 0) return rc;
    return switch (c.errno(rc)) {
        .NOMEM => error.SystemResources,
        .AGAIN => error.ProcessFdQuotaExceeded,
        else => error.Unexpected,
    };
}

pub const F = c.F;

/// Replacement for std.time.timestamp() (removed in 0.16). Returns Unix seconds.
pub fn timestamp() i64 {
    var ts: std.posix.timespec = undefined;
    _ = std.os.linux.clock_gettime(std.os.linux.CLOCK.REALTIME, &ts);
    return ts.sec;
}

/// Replacement for std.posix.open() (removed in 0.16).
pub fn openZ(path: [*:0]const u8, flags: std.posix.O, mode: mode_t) !c_int {
    const rc = c.open(path, flags, mode);
    if (rc >= 0) return rc;
    return error.OpenFailed;
}

/// Replacement for std.posix.dup2() (removed in 0.16).
pub fn dup2(old: fd_t, new: fd_t) !void {
    const rc = c.dup2(old, new);
    if (rc < 0) return error.Dup2Failed;
}

/// Replacement for std.fs.readLinkAbsolute() (removed in 0.16).
pub fn readLinkAbsolute(path: []const u8, buf: []u8) ![]u8 {
    var path_z: [std.posix.PATH_MAX:0]u8 = undefined;
    if (path.len >= path_z.len) return error.NameTooLong;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const rc = c.readlink(&path_z, buf.ptr, buf.len);
    if (rc < 0) return error.ReadLinkFailed;
    return buf[0..@intCast(rc)];
}

/// Minimal File handle to mimic 0.15 std.fs.File API for libc-backed I/O.
pub const File = struct {
    fd: c_int,

    pub fn close(self: File) void {
        _ = c.close(self.fd);
    }

    pub fn read(self: File, buf: []u8) !usize {
        const rc = c.read(self.fd, buf.ptr, buf.len);
        if (rc < 0) return error.ReadFailed;
        return @intCast(rc);
    }

    pub fn writeAll(self: File, data: []const u8) !void {
        var written: usize = 0;
        while (written < data.len) {
            const rc = c.write(self.fd, data.ptr + written, data.len - written);
            if (rc <= 0) return error.WriteFailed;
            written += @intCast(rc);
        }
    }

    pub fn readToEndAlloc(self: File, allocator: std.mem.Allocator, max_bytes: usize) ![]u8 {
        var list: std.ArrayListUnmanaged(u8) = .empty;
        defer list.deinit(allocator);
        var buf: [4096]u8 = undefined;
        while (true) {
            const n = try self.read(&buf);
            if (n == 0) break;
            if (list.items.len + n > max_bytes) return error.FileTooBig;
            try list.appendSlice(allocator, buf[0..n]);
        }
        return list.toOwnedSlice(allocator);
    }
};

pub fn openFileAbsolute(path: []const u8, _: anytype) !File {
    var path_z: [std.posix.PATH_MAX:0]u8 = undefined;
    if (path.len >= path_z.len) return error.NameTooLong;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const flags: std.posix.O = .{ .ACCMODE = .RDONLY };
    const rc = c.open(&path_z, flags, @as(c_uint, 0));
    if (rc < 0) return error.FileNotFound;
    return .{ .fd = rc };
}

pub fn createFileAbsolute(path: []const u8, _: anytype) !File {
    var path_z: [std.posix.PATH_MAX:0]u8 = undefined;
    if (path.len >= path_z.len) return error.NameTooLong;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const flags: std.posix.O = .{ .ACCMODE = .WRONLY, .CREAT = true, .TRUNC = true };
    const rc = c.open(&path_z, flags, @as(c_uint, 0o644));
    if (rc < 0) return error.OpenFailed;
    return .{ .fd = rc };
}

pub fn accessAbsolute(path: []const u8, _: anytype) !void {
    var path_z: [std.posix.PATH_MAX:0]u8 = undefined;
    if (path.len >= path_z.len) return error.NameTooLong;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const rc = c.access(&path_z, 0); // F_OK
    if (rc < 0) return error.FileNotFound;
}

/// Mimic std.fs.cwd().X — backed by libc.
pub const Cwd = struct {
    pub fn access(_: Cwd, path: []const u8, _: anytype) !void {
        return accessAbsolute(path, .{});
    }
    pub fn openFile(_: Cwd, path: []const u8, _: anytype) !File {
        return openFileAbsolute(path, .{});
    }
    pub fn createFile(_: Cwd, path: []const u8, _: anytype) !File {
        return createFileAbsolute(path, .{});
    }
    pub fn makePath(_: Cwd, path: []const u8) !void {
        // Recursively create directories
        var path_z: [std.posix.PATH_MAX:0]u8 = undefined;
        if (path.len >= path_z.len) return error.NameTooLong;
        @memcpy(path_z[0..path.len], path);
        path_z[path.len] = 0;
        // First try the full path
        const rc = c.mkdir(&path_z, 0o755);
        if (rc == 0 or c.errno(rc) == .EXIST) return;
        // Otherwise walk the path recursively
        var i: usize = 1;
        while (i < path.len) : (i += 1) {
            if (path[i] == '/') {
                path_z[i] = 0;
                _ = c.mkdir(&path_z, 0o755);
                path_z[i] = '/';
            }
        }
        _ = c.mkdir(&path_z, 0o755);
    }
};

pub fn cwd() Cwd {
    return .{};
}

/// Minimal directory iterator using libc opendir/readdir for builtin_status.
pub const Dir = struct {
    handle: *std.c.DIR,

    pub fn close(self: Dir) void {
        _ = std.c.closedir(self.handle);
    }

    pub const Entry = struct {
        name: []const u8,
        kind: Kind,

        pub const Kind = enum { file, directory, sym_link, other };
    };

    pub const Iterator = struct {
        dir: Dir,
        name_buf: [256]u8 = undefined,

        pub fn next(self: *Iterator) !?Entry {
            while (true) {
                const dent = std.c.readdir(self.dir.handle) orelse return null;
                const name_z: [*:0]const u8 = @ptrCast(&dent.*.name);
                const name = std.mem.span(name_z);
                if (std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..")) continue;
                if (name.len > self.name_buf.len) continue;
                @memcpy(self.name_buf[0..name.len], name);
                const kind: Entry.Kind = switch (dent.*.type) {
                    std.c.DT.DIR => .directory,
                    std.c.DT.REG => .file,
                    std.c.DT.LNK => .sym_link,
                    else => .other,
                };
                return .{ .name = self.name_buf[0..name.len], .kind = kind };
            }
        }
    };

    pub fn iterate(self: Dir) Iterator {
        return .{ .dir = self };
    }
};

extern "c" fn execvp(file: [*:0]const u8, argv: [*:null]const ?[*:0]const u8) c_int;
extern "c" fn waitpid(pid: c.pid_t, status: ?*c_int, options: c_int) c.pid_t;

/// Spawn `argv[0]` (looked up via PATH), capture stdout to `buf`,
/// and return the slice that was read. Stderr is discarded.
/// Returns null on any failure.
pub fn runCaptureStdout(argv: []const [*:0]const u8, buf: []u8) ?[]u8 {
    if (argv.len == 0) return null;
    const pipe_fds = pipe() catch return null;
    const pid = fork() catch {
        close(pipe_fds[0]);
        close(pipe_fds[1]);
        return null;
    };
    if (pid == 0) {
        // Child
        _ = c.dup2(pipe_fds[1], 1); // stdout
        // /dev/null for stderr
        const devnull = c.open("/dev/null", .{ .ACCMODE = .WRONLY }, @as(c_uint, 0));
        if (devnull >= 0) {
            _ = c.dup2(devnull, 2);
            _ = c.close(devnull);
        }
        _ = c.close(pipe_fds[0]);
        _ = c.close(pipe_fds[1]);

        // Build null-terminated argv for execvp
        var stack_argv: [16:null]?[*:0]const u8 = undefined;
        var i: usize = 0;
        while (i < argv.len and i < 15) : (i += 1) {
            stack_argv[i] = argv[i];
        }
        stack_argv[i] = null;
        _ = execvp(argv[0], &stack_argv);
        std.process.exit(127);
    }
    close(pipe_fds[1]);
    var total: usize = 0;
    while (total < buf.len) {
        const rc = c.read(pipe_fds[0], buf.ptr + total, buf.len - total);
        if (rc <= 0) break;
        total += @intCast(rc);
    }
    close(pipe_fds[0]);
    var status: c_int = 0;
    _ = waitpid(pid, &status, 0);
    return buf[0..total];
}

pub fn openDirAbsolute(path: []const u8, _: anytype) !Dir {
    var path_z: [std.posix.PATH_MAX:0]u8 = undefined;
    if (path.len >= path_z.len) return error.NameTooLong;
    @memcpy(path_z[0..path.len], path);
    path_z[path.len] = 0;
    const handle = std.c.opendir(&path_z) orelse return error.NotDir;
    return .{ .handle = handle };
}
