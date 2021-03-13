export mlstyle_add_deprecation_msg!, mlstyle_report_deprecation_msg!
const threadsafe_msgs = Vector{String}[String[] for _ in Base.Threads.nthreads()]

function mlstyle_add_deprecation_msg!(msg::String)
    push!(threadsafe_msgs[Base.Threads.threadid()], msg)
end

function mlstyle_report_deprecation_msg!(ln::LineNumberNode)
    msgs = threadsafe_msgs[Base.Threads.threadid()]
    isempty(msgs) || begin
        @warn "Deprecated use detected at $(ln.file):$(ln.line)."
        for msg in msgs
            @warn msg
        end
        empty!(msgs)
    end
end
