/**
 * Ceiled Binary Logarithm of a Natural Number
 *
 * This constant function returns the binary logarithm (i.e., the logarithm to the base 2) of
 * a natural number, rounded towards plus infinity.
 *
 * Copyright (c) 2016 Integrated Systems Laboratory, ETH Zurich.  This is free software under the
 * terms of the GNU General Public License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.  This software is distributed
 * without any warranty; without even the implied warranty of merchantability or fitness for
 * a particular purpose.
 */

`ifndef LOG2_SV
`define LOG2_SV

function integer log2;
  input longint val;
  begin

    val = val - 1;
    for (log2 = 0; val > 0; log2 = log2+1)
      val = val >> 1;

  end
endfunction

`endif // LOG2_SV

// vim: ts=2 sw=2 sts=2 et nosmartindent autoindent tw=100
