`ifndef LOG2_SV
`define LOG2_SV

function integer log2;
  input integer val;
  begin
    val = val - 1;
    for (log2 = 0; val > 0; log2 = log2+1)
      val = val >> 1;
  end
endfunction

`endif // LOG2_SV

// vim: ts=2 sw=2 sts=2 et tw=100
