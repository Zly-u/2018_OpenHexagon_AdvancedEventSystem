local function tablePrint(table, tabulation)
	local tbe = tabulation or ""
	if type(table) ~= "table" then print(table); return end

	for i, v in pairs(table) do
		print(tbe..tostring(i), v)
		if type(v) == "table" and v ~= table then
			local tab = tbe.."\t"
			tablePrint(v, tab)
		end
	end
end

return tablePrint