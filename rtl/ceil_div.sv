/**
 * Ceiled Division of Two Natural Numbers
 *
 * This constant function returns the quotient of two natural numbers, rounded towards plus
 * infinity.
 *
 * Copyright (c) 2016 Integrated Systems Laboratory, ETH Zurich.  This is free software under the
 * terms of the GNU General Public License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.  This software is distributed
 * without any warranty; without even the implied warranty of merchantability or fitness for
 * a particular purpose.
 */

`ifndef CEIL_DIV_SV
`define CEIL_DIV_SV

function integer ceil_div;
  input integer dividend, divisor;
  integer remainder;
  begin

    if (dividend < 0)
      $fatal(1, "Dividend %0d is not a natural number!", dividend);

    if (divisor < 0)
      $fatal(1, "Divisor %0d is not a natural number!", divisor);

    if (divisor == 0) begin
      $fatal(1, "Division by zero!");
    end

    remainder = dividend;
    for (ceil_div = 0; remainder > 0; ceil_div = ceil_div+1)
      remainder = remainder - divisor;

  end
endfunction

`endif // CEIL_DIV_SV

// vim: ts=2 sw=2 sts=2 et nosmartindent autoindent tw=100
